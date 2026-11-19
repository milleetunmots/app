class ChildSupport::CallerStopSupportService

  FAMILY_BUNDLE = ['Arrêt · Famille pose problème / Inscrite sans accord / Ne veut pas du programme / Pratiques très avancées', 'arret_accompagnement'].freeze
  HEALTH_PROFESSIONAL_BUNDLE = ['Arrêt · Professionnel·le de santé qui teste', 'arret_professionnel_sante'].freeze
  LANGUAGE_BARRIER_BUNDLE = ['Arrêt · Pas assez francophone', 'arret_barriere_langue'].freeze

  STOP_SUPPORT_INFORMATIONS = {
    program: { tag: 'arrêt accompagnante - programme', bundle: FAMILY_BUNDLE, motive: 'la famille ne veut pas du programme complet' },
    very_advanced_practices: { tag: 'arrêt accompagnante - pratiques parentales avancées', bundle: FAMILY_BUNDLE, motive: 'la famille a des pratiques très avancées' },
    problematic_case: { tag: 'arrêt accompagnante - problèmes', bundle: FAMILY_BUNDLE, motive: 'la famille me pose problème (insulte, propos gênants, raccroche au nez, etc)' },
    professional: { tag: 'arrêt accompagnante - pro de santé', bundle: HEALTH_PROFESSIONAL_BUNDLE, motive: "La famille est un.e professionnel.le de santé qui souhaite tester l'accompagnement" },
    registered_by_partner_without_consent: { tag: 'arrêt accompagnante - inscription sans accord', bundle: FAMILY_BUNDLE, motive: 'la famille a été inscrite par un partenaire sans son accord' },
    family_limited_french_for_support: { tag: 'arrêt accompagnante - non francophone', bundle: LANGUAGE_BARRIER_BUNDLE, motive: "la famille n'est pas assez francophone pour tirer profit de l’accompagnement" },
    family_unresponsive_after_adaptation: { tag: 'arrêt accompagnante - non francophone adaptation KO', bundle: LANGUAGE_BARRIER_BUNDLE, motive: "je vois que la famille ne me répond plus / j'ai des doutes sur l'impact du programme" }
  }.freeze

  attr_reader :error, :notice

  def initialize(supporter_id, child_support_id, reason, details)
    @supporter = AdminUser.find(supporter_id)
    @child_support = ChildSupport.find(child_support_id)
    @reason = reason
    @details = details
    @error = nil
    @notice = 'Accompagnement arrêté et message de désistement envoyé aux parents'
  end

  def call
    ActiveRecord::Base.transaction do
      add_stop_support_informations
      stop_support
      add_tag
      send_message
    end
    self
  end

  private

  def add_stop_support_informations
    @child_support.stop_support_caller_id = @supporter.id
    @child_support.stop_support_reason = STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:motive]
    @child_support.stop_support_date = DateTime.now
    @child_support.stop_support_details = @details
    @error = "Les informations n'ont pas pu être ajoutée à la fiche de suivie" unless @child_support.save
    raise ActiveRecord::Rollback unless @error.nil?
  end

  def stop_support
    @child_support.children.each do |child|
      if child.group.present?
        child.group_status = 'stopped'
        child.group_end = Time.zone.today
      else
        child.group_status = 'not_supported'
      end
      @error = "L'accompagnement de #{child.first_name} n'a pas pu être arrêté" unless child.save
      raise ActiveRecord::Rollback unless @error.nil?
    end
    @child_support.important_information =
      "#{@child_support.important_information}\nAccompagnement arrêté le #{DateTime.now.strftime('%d/%m/%Y')} pour le motif \"#{STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:motive]}\" à la demande de #{@supporter.name}"
    @child_support.save
  end

  def add_tag
    @child_support.tag_list += [STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:tag]].flatten
    @child_support.save!
    @error = "Le tag n'a pas pu être ajouté à la fiche de suivi" unless @child_support.save
    raise ActiveRecord::Rollback unless @error.nil?
  end

  def send_message
    return @notice = 'Accompagnement arrêté, aucun parent à contacter : aucun message envoyé' if recipients.empty?

    bundle = find_bundle
    return @notice = 'Accompagnement arrêté, message non envoyé' unless bundle

    program_messages(bundle) == recipients.size ? raise(ActiveRecord::Rollback) : @error = nil
  end

  def find_bundle
    name, key = STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:bundle]
    bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
    Rollbar.error("Trio introuvable : « #{name} » (clé #{key}), message non envoyé") unless bundle
    bundle
  end

  def program_messages(bundle)
    link_id = RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id if bundle.link1_id
    recipients.count do |recipient|
      program_message_service = ProgramMessageService.new(
        DateTime.now.strftime('%Y-%m-%d'), DateTime.now.strftime('%H:%M'), [recipient], bundle.body1, bundle.rcs_media_id_to_send(1), link_id, nil, nil, nil, Child::GROUP_STATUS
      ).call
      @error = program_message_service.errors.join("\n") if program_message_service.errors.any?
      program_message_service.errors.any?
    end
  end

  def recipients
    recipients = []
    recipients << "parent.#{@child_support.parent1.id}" if @child_support.parent1.should_be_contacted?
    return recipients if @child_support.parent2.nil?

    recipients << "parent.#{@child_support.parent2.id}" if @child_support.parent2.should_be_contacted?
    recipients
  end
end
