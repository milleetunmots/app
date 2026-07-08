class AdminUser

  class ImportGroupSubscriptionsService

    attr_reader :errors

    def initialize
      @errors = []
    end

    def call
      subscriptions = build_subscriptions
      if subscriptions.empty? && AdminUser.where.not(group_subscriptions: {}).exists?
        @errors << 'Aucun positionnement récupéré depuis Airtable, import ignoré par sécurité.'
        return self
      end

      apply_subscriptions(subscriptions)
      self
    end

    private

    # { admin_user_id => { "group_id" => families_count } }
    def build_subscriptions
      subscriptions = {}
      Airtables::GroupSubscription.validated.each do |registration|
        group = group_for(registration)
        next if group.nil?

        admin_user_id = admin_user_id_for(registration)
        next if admin_user_id.nil?

        (subscriptions[admin_user_id] ||= {})[group.id.to_s] = registration.families_count.to_i
      end
      subscriptions
    end

    def apply_subscriptions(subscriptions)
      admin_user_ids = subscriptions.keys | AdminUser.where.not(group_subscriptions: {}).ids
      AdminUser.where(id: admin_user_ids).find_each do |admin_user|
        new_subscriptions = subscriptions[admin_user.id] || {}
        removed_group_ids = admin_user.group_subscriptions.keys - new_subscriptions.keys
        destroy_obsolete_overrides(admin_user, removed_group_ids)
        admin_user.update!(group_subscriptions: new_subscriptions) unless admin_user.group_subscriptions == new_subscriptions
      end
    end

    # Une accompagnante qui n'est plus positionnée perd ses plages personnalisées,
    # sauf si des familles lui ont déjà été attribuées (la source est alors l'application)
    # ou si le groupe vient d'être programmé (la distribution des familles n'a pas encore eu lieu).
    def destroy_obsolete_overrides(admin_user, removed_group_ids)
      removed_group_ids.each do |group_id|
        next if ChildSupport.in_group(group_id).all_supported_by(admin_user.id).any?
        next if Group.kept.exists?(id: group_id, is_programmed: true)

        CallSessionDateOverride.where(admin_user: admin_user, group_id: group_id).destroy_all
      end
    end

    def group_for(registration)
      cohort = cohorts_by_airtable_id[registration.airtable_cohort_id]
      if cohort.nil? || cohort.name.blank?
        @errors << "Cohorte Airtable introuvable pour l'inscription #{registration.registration_id}"
        return
      end
      return unless future_cohort?(cohort)

      group = eligible_groups.find { |eligible_group| group_name_matches?(eligible_group.name, cohort.name) }
      return group if group.present?

      # Groupe déjà programmé : hors périmètre, on ignore silencieusement
      @errors << "Cohorte introuvable dans l'application : #{cohort.name}" if group_names.none? { |group_name| group_name_matches?(group_name, cohort.name) }
      nil
    end

    def future_cohort?(cohort)
      cohort.start_date.present? && Date.parse(cohort.start_date) > Time.zone.today
    rescue ArgumentError
      false
    end

    # Le nom des groupes est standardisé avec un préfixe date ("2026/09/07 - Septembre26-A"),
    # et l'espacement peut varier ("Juin 26 - A" vs "Juin26-A" sur Airtable).
    def group_name_matches?(group_name, cohort_name)
      group_name.sub(%r{^\d{4}/\d{2}/\d{2} - }, '').delete(' ').casecmp?(cohort_name.delete(' '))
    end

    def admin_user_id_for(registration)
      airtable_caller_id = registration.airtable_caller_id
      admin_user_id = airtable_caller_id && admin_user_ids_by_airtable_caller_id(airtable_caller_id)
      @errors << "Accompagnante introuvable dans la base pour l'inscription #{registration.registration_id}" if admin_user_id.nil?
      admin_user_id
    rescue Airrecord::Error => e
      @errors << "Erreur Airtable pour l'inscription #{registration.registration_id} : #{e.message}"
      nil
    end

    def admin_user_ids_by_airtable_caller_id(airtable_caller_id)
      @admin_user_ids ||= {}
      return @admin_user_ids[airtable_caller_id] if @admin_user_ids.key?(airtable_caller_id)

      @admin_user_ids[airtable_caller_id] = AdminUser.find_by(id: Airtables::Caller.caller_id_by_airtable_caller_id(airtable_caller_id))&.id
    end

    def eligible_groups
      @eligible_groups ||= Group.kept.where(is_programmed: false).where('started_at > ?', Time.zone.today).to_a
    end

    def cohorts_by_airtable_id
      @cohorts_by_airtable_id ||= Airtables::Group.all.index_by(&:id)
    end

    def group_names
      @group_names ||= Group.kept.pluck(:name)
    end
  end
end
