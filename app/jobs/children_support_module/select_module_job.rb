class ChildrenSupportModule
  class SelectModuleJob < ApplicationJob
    def perform(group_id)
      errors = {}
      group = Group.includes(:children).find(group_id)

      group.children.each do |child|
        service = ChildSupport::SelectModuleService.new(
          child,
          Date.today.next_day.sunday? ? Date.today.next_day : Date.today,
          "12:30"
        ).call
        errors[child.id] = service.errors
      end

      raise errors.to_json if errors.any?
    end
  end
end
