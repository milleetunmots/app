class ChildrenSupportModule
  class SelectDefaultSupportModuleService

    LESS_THAN_ELEVEN_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME = ENV['LESS_THAN_ELEVEN_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME'].freeze
    MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME = ENV['MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME'].freeze

    def initialize(group_id)
      @group = Group.find(group_id)
      @children_with_missing_child_support = []
      @children_support_modules_with_support_module_selected = []
      @active_children = @group.children.where(group_status: 'active').ids
      @active_current_children = ChildSupport.includes(:children).where(children: { id: @active_children }).map { |child_support| child_support.current_child.id }
    end

    def call
      assign_default_support_module
      retry_assign_default_support_module if missing_support_modules_for_current_children?
      assign_specific_default_support_module if missing_support_modules_for_current_children?
      sleep(3)
      assign_specific_default_support_module if missing_support_modules?
      if @children_with_missing_child_support.any?
        Rollbar.error(
          "Certains enfants de la cohorte #{@group.id} n'ont pas de fiche de suivi",
          children: @children_with_missing_child_support.uniq!,
          source: 'ChildrenSupportModule::SelectDefaultSupportModuleService'
        )
      end
      if missing_support_modules?
        Rollbar.error(
          "Certains enfants principaux de la cohorte #{group.id} n'ont pas de children_support_module",
          current_children: @missing_support_modules,
          source: 'ChildrenSupportModule::SelectDefaultSupportModuleService'
        )
      end
      if children_support_modules_with_support_module_selected.any?
        Rollbar.error(
          'SelectDefaultSupportModuleService : Fail safe triggered',
          group_id: @group.id,
          children_support_modules: @children_support_modules_with_support_module_selected,
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

          default_support_module_id = csm.available_support_module_list.reject(&:blank?).first
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
      ChildSupport::FillParentsAvailableSupportModulesService.new(group_id, false).call
      assign_default_support_module
    end

    def assign_specific_default_support_module
      five_to_eleven_specific_default_support_module = SupportModule.where(name: LESS_THAN_ELEVEN_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME).where("'#{SupportModule::FIVE_TO_ELEVEN}' = ANY (age_ranges)").first
      twelve_to_seventeen_specific_default_support_module = SupportModule.where(name: MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME).where("'#{SupportModule::TWELVE_TO_SEVENTEEN}' = ANY (age_ranges)").first
      eighteen_to_twenty_three_specific_default_support_module = SupportModule.where(name: MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME).where("'#{SupportModule::EIGHTEEN_TO_TWENTY_THREE}' = ANY (age_ranges)").first
      twenty_four_to_twenty_nine_specific_default_support_module = SupportModule.where(name: MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME).where("'#{SupportModule::TWENTY_FOUR_TO_TWENTY_NINE}' = ANY (age_ranges)").first
      thirty_to_thirty_five_specific_default_support_module = SupportModule.where(name: MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME).where("'#{SupportModule::THIRTY_TO_THIRTY_FIVE}' = ANY (age_ranges)").first

      @missing_support_modules.each do |children_support_module|
        support_module =
          case children_support_module.child.months
          when 5..11
            five_to_eleven_specific_default_support_module
          when 12..17
            twelve_to_seventeen_specific_default_support_module
          when 18..23
            eighteen_to_twenty_three_specific_default_support_module
          when 24..29
            twenty_four_to_twenty_nine_specific_default_support_module
          when 30..35
            thirty_to_thirty_five_specific_default_support_module
          end
        @children_support_modules_with_support_module_selected << children_support_module.id if children_support_module.update(support_module: support_module)
      end
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
