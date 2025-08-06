class ChildrenSupportModule
  class VerifyChosenModulesTaskJob < ApplicationJob
    def perform(group_id)
      group = Group.includes(children: :children_support_modules).find(group_id)
      current_support_module_index = group.support_module_programmed + 1
      missing_support_modules = ChildrenSupportModule.where(support_module: nil, child_id: group.children.where(group_status: 'active').ids, module_index: current_support_module_index)
      description_text = ActionController::Base.helpers.link_to('Compléter les modules sans choix', Rails.application.routes.url_helpers.admin_children_support_modules_url(scope: 'without_choice', q: { group_id_in: [group_id], module_index_equals: current_support_module_index }), target: '_blank', class: 'blue')
      description_text << ' - '
      description_text << ActionController::Base.helpers.link_to('Compléter les modules "laisse le choix à 1001mots"', Rails.application.routes.url_helpers.admin_children_support_modules_url(scope: 'with_the_choice_to_make_by_us', q: { group_id_in: [group_id], module_index_equals: current_support_module_index }), target: '_blank', class: 'blue')
      return unless missing_support_modules.any?

      Task::CreateAutomaticTaskService.new(
        title: "Compléter les modules pour la cohorte \"#{group.name}\"",
        description: description_text
      ).call
      Rollbar.error(description_text)
    end
  end
end
