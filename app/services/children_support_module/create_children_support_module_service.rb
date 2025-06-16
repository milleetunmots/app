class ChildrenSupportModule
  class CreateChildrenSupportModuleService

    def initialize(group_id)
      @errors = {}
      @group = Group.find(group_id)
      @next_module_index = @group.support_module_programmed + 1
    end

    def call
      @group.children.includes(:parent1, :parent2, :child_support).where(group_status: 'active').find_each do |child|
        unless child.child_support
          @errors["child: #{child.id}"] = "Cet enfant n'a pas de fiche de suivi"
          next
        end

        unless ChildrenSupportModule.not_programmed.exists?(child_id: child.id, parent_id: child.parent1.id)
          parent1_children_support_module = ChildrenSupportModule.create(child_id: child.id,
                                                                       parent_id: child.parent1.id,
                                                                       available_support_module_list: child.child_support&.parent1_available_support_module_list.reject(&:blank?),
                                                                       module_index: @next_module_index)
        end

        if child.parent2
          unless ChildrenSupportModule.not_programmed.exists?(child_id: child.id, parent_id: child.parent2.id)
            parent2_children_support_module = ChildrenSupportModule.create(child_id: child.id,
                                                                       parent_id: child.parent2.id,
                                                                       available_support_module_list: child.child_support&.parent2_available_support_module_list.reject(&:blank?),
                                                                       module_index: @next_module_index)
          end
        end

        @errors[child.id] = handle_errors([parent1_children_support_module, parent2_children_support_module]) if parent1_children_support_module&.errors&.any? || parent2_children_support_module&.errors&.any?
      end
      raise @errors.to_json if @errors.any?

      self
    end

    private

    def handle_errors(children_support_modules)
      errors = []

      children_support_modules.compact.each do |csm|
        errors << csm.errors if csm.errors.any?
      end

      errors
    end
  end
end
