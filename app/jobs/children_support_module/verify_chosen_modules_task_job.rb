class ChildrenSupportModule
  class VerifyChosenModulesTaskJob < ApplicationJob
    def perform(group_id)
      group = Group.includes(children: :children_support_modules).find(group_id)
      logistics_team_members = AdminUser.all_logistics_team_members
      missing_support_modules = ChildrenSupportModule.where(support_module: nil, child_id: group.children.where(group_status: 'active').ids)
      description_text = ActionController::Base.helpers.link_to('Compléter les modules sans choix', Rails.application.routes.url_helpers.admin_children_support_modules_url(scope: 'without_choice', q: { active_group_id_in: [group_id] }), target: '_blank', class: 'blue')
      description_text << ' - '
      description_text << ActionController::Base.helpers.link_to('Compléter les modules "laisse le choix à 1001mots"', Rails.application.routes.url_helpers.admin_children_support_modules_url(scope: 'with_the_choice_to_make_by_us', q: { active_group_id_in: [group_id] }), target: '_blank', class: 'blue')
      return unless missing_support_modules.any?

      operation_project_manager = AdminUser.find_by(email: ENV['OPERATION_PROJECT_MANAGER_EMAIL'])
      return unless operation_project_manager

      Task.create(
        assignee_id: operation_project_manager.id,
        title: "Compléter les modules pour la cohorte \"#{group.name}\"",
        description: description_text,
        due_date: Time.zone.today
      )
      Rollbar.error(description_text)
    end
  end
end
