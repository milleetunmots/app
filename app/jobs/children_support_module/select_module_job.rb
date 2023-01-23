class ChildrenSupportModule
  class SelectModuleJob < ApplicationJob
    def perform(group_id)
      errors = {}
      group = Group.find(group_id)

      group.children.where(group_status: "active").find_each do |child|
        service = ChildSupport::SelectModuleService.new(
          child,
          Date.today.next_day.sunday? ? Date.today.next_day : Date.today,
          "12:30"
        ).call
        errors[child.id] = service.errors if service.errors.any?
      end

      raise errors.to_json if errors.any?
    end
  end
end
