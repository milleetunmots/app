class ChildrenSupportModule
  class SelectDefaultSupportModuleService

    LESS_THAN_ELEVEN_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME = ENV['LESS_THAN_ELEVEN_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME'].freeze
    MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME = ENV['MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME'].freeze
    # Dernier mois couvert par un module par défaut (cf. default_module_age_range_for).
    DEFAULT_MODULE_AGE_CAP_IN_MONTHS = 35

    def initialize(group_id)
      @group = Group.find(group_id)
      @children_with_missing_child_support = []
      @children_support_modules_with_support_module_selected = []
      @children_support_modules_without_support_module = []
      @active_children = @group.children.where(group_status: 'active').ids
      @active_current_children = ChildSupport.includes(:children).where(children: { id: @active_children }).filter_map { |child_support| child_support.current_child&.id }
    end

    def call
      # 1. First attempt at assigning the default support module
      assign_default_support_module
      # 2. If support modules are missing for current children, we retry.
      # This new attempt is preceded by updating the available support modules for the parents.
      retry_assign_default_support_module if missing_support_modules_for_current_children?
      # 3. If support modules are still missing the current children, we use an age-based fallback module.
      assign_specific_default_support_module if missing_support_modules_for_current_children?
      # 3 seconds pause for ChildrenSupportModule callbacks.
      sleep(3)
      # 4. Last attempt using the fallback module for all active children (not only the current ones)
      assign_specific_default_support_module if missing_support_modules?
      if @children_with_missing_child_support.any?
        Rollbar.error(
          "Certains enfants de la cohorte #{@group.id} n'ont pas de fiche de suivi",
          children: @children_with_missing_child_support.uniq,
          source: 'ChildrenSupportModule::SelectDefaultSupportModuleService'
        )
      end
      if @children_support_modules_with_support_module_selected.any?
        Rollbar.error(
          'SelectDefaultSupportModuleService : Fail safe triggered',
          group_id: @group.id,
          children_support_modules: @children_support_modules_with_support_module_selected.uniq,
          source: 'ChildrenSupportModule::SelectDefaultSupportModuleService'
        )
      end
      if @children_support_modules_without_support_module.any?
        Rollbar.error(
          'SelectDefaultSupportModuleService : aucun module attribuable',
          group_id: @group.id,
          children_support_modules: @children_support_modules_without_support_module.uniq,
          source: 'ChildrenSupportModule::SelectDefaultSupportModuleService'
        )
      end
      self
    end

    private

    def assign_default_support_module
      @group.children.where(group_status: 'active').find_each do |child|
        @children_with_missing_child_support << child.id and next unless child.child_support

        next if child.have_siblings_on_same_group? && !child.current_child?

        child.children_support_modules.where(support_module: nil).each do |csm|
          # when there is no support_module chosen for a parent, we take the one chosen by the other parent
          # if there is no support_module chosen by the other parent, we take the first one available

          default_support_module_id = csm.available_support_module_list&.reject(&:blank?)&.first
          the_other_parent = csm.parent == csm.child.parent1 ? csm.child.parent2 : csm.child.parent1
          if the_other_parent.present? && the_other_parent.children_support_modules.any?
            the_other_parent_csm = the_other_parent.children_support_modules.where(child: child).latest_first.first

            already_done_support_module_ids = child.children_support_modules.where(parent: csm.parent).pluck(:support_module_id)

            default_support_module_id = the_other_parent_csm.support_module_id if the_other_parent_csm&.support_module_id.present? && already_done_support_module_ids.exclude?(the_other_parent_csm&.support_module_id)
          end

          csm.update(support_module_id: default_support_module_id)
        end
      end
    end

    def retry_assign_default_support_module
      module_index = @group.support_module_sent_dates&.sort_by { |key, _| key }&.to_h&.find { |_, sent_date| sent_date > Time.zone.now }&.first
      unless module_index
        Rollbar.error(
          'SelectDefaultSupportModuleService : retry assign default support module failed, group without support_module_sent_dates',
          group_id: @group.id,
          support_module_sent_dates: @group.support_module_sent_dates,
          source: 'ChildrenSupportModule::SelectDefaultSupportModuleService'
        )
        return
      end

      ChildSupport::FillParentsAvailableSupportModulesService.new(@group.id, module_index).call
      assign_default_support_module
    end

    def assign_specific_default_support_module
      @missing_support_modules.each do |children_support_module|
        support_module = specific_default_support_module_for(children_support_module.child)

        # `update(support_module: nil)` réussirait sans rien changer — ces
        # lignes ont déjà `support_module: nil` — et l'enfant serait rangé
        # parmi ceux que le fail safe a servis. On le compte plutôt comme
        # sans module attribuable, ce qui a sa propre alerte.
        if support_module.nil?
          @children_support_modules_without_support_module << children_support_module.id
          next
        end

        @children_support_modules_with_support_module_selected << children_support_module.id if children_support_module.update(support_module: support_module)
      end
    end

    # Renvoie nil dans deux cas, tous deux normaux : l'enfant a moins de 4 mois
    # — il n'a rien à recevoir —, ou aucun module par défaut n'existe pour sa
    # tranche. Les noms de ces modules viennent de l'ENV, leur existence est une
    # question de données : l'appelant compte ces enfants et les remonte à
    # Rollbar plutôt que de les considérer comme servis.
    #
    # Le cache mémorise aussi les absences (`key?`), pour ne pas rejouer à
    # chaque enfant de la cohorte une requête qui ne trouvera rien.
    def specific_default_support_module_for(child)
      age_range = default_module_age_range_for(child)
      return if age_range.blank?

      @specific_default_support_modules ||= {}
      return @specific_default_support_modules[age_range] if @specific_default_support_modules.key?(age_range)

      name = age_range == SupportModule::FOUR_TO_ELEVEN ? LESS_THAN_ELEVEN_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME : MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME
      @specific_default_support_modules[age_range] = SupportModule.where('name ILIKE ?', "#{name}%")
                                                                  .where("'#{age_range}' = ANY (age_ranges)")
                                                                  .first
    end

    # Les modules par défaut ne couvrent que jusqu'à THIRTY_TO_THIRTY_FIVE —
    # c'est la liste qu'énumérait l'ancien `case`. Un enfant plus âgé emprunte
    # le module de cette tranche plutôt que de rester sans module ; avant, il
    # gardait `support_module: nil`.
    #
    # Le plafond porte sur les mois, pas sur la tranche : `age_range_for`
    # reste la seule source du découpage, et le jour où un module par défaut
    # existera pour 36-40, il suffira de relever cette constante.
    def default_module_age_range_for(child)
      SupportModule.age_range_for_capped(child.months, cap: DEFAULT_MODULE_AGE_CAP_IN_MONTHS)
    end

    def missing_support_modules_for_current_children?
      @missing_support_modules = ChildrenSupportModule.not_programmed.where(support_module: nil, child_id: @active_current_children)
      @missing_support_modules.any?
    end

    def missing_support_modules?
      @missing_support_modules = ChildrenSupportModule.not_programmed.where(support_module: nil, child_id: @active_children)
      @missing_support_modules.any?
    end
  end
end
