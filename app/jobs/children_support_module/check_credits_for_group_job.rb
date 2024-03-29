class ChildrenSupportModule
  class CheckCreditsForGroupJob < ApplicationJob
    def perform(group_id)
      group = Group.find(group_id)
      children_support_module_ids = ChildrenSupportModule.not_programmed.where(child_id: group.children.where(group_status: "active").ids)
      check_service = ChildrenSupportModule::CheckCreditsService.new(children_support_module_ids).call
      return unless check_service.errors.any?

      logistics_team_members = AdminUser.all_logistics_team_members
      logistics_team_members.each do |ltm|
        Task.create(
          assignee_id: ltm.id,
          title: "Il n'y a pas assez de crédits pour la programmation des modules de la cohorte : \"#{group.name}\"",
          description: check_service.errors.join("<br>"),
          due_date: Time.zone.today
        )
      end
      Rollbar.error("Pas assez de crédits pour la programmation des modules de la cohorte #{group_id}", errors: check_service.errors)
    end
  end
end
