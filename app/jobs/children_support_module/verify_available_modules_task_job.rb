class ChildrenSupportModule
  class VerifyAvailableModulesTaskJob < ApplicationJob
    def perform(group_id, verification_date)

      group = Group.includes(children: :child_support).find(group_id)
      logistics_team_members = AdminUser.all_logistics_team_members
      child_support_link = {}

      group.children.each do |child|
        if child.child_support.parent1_available_support_module_list.nil? ||
          child.child_support.parent1_available_support_module_list.reject(&:blank?).empty? ||
          (
            child.child_support.parent2 &&
              (
                child.child_support.parent2_available_support_module_list.nil? ||
                child.child_support.parent2_available_support_module_list.reject(&:blank?).empty?
              )
          )
          child_support_link[:"#{child.decorate.name}"] = Rails.application.routes.url_helpers.edit_admin_child_support_url(id: child.child_support.id)
        end
      end

      description_text = "Compléter le choix de modules disponibles pour :"
      child_support_link.each { |name, link| description_text << "<br>#{ActionController::Base.helpers.link_to(name, link, target: '_blank', class: 'blue')}" }
      logistics_team_members.each { |ltm| Task.create(assignee_id: ltm.id, title: "Il manque des choix à préparer pour la cohorte \"#{group.name}\"", description: description_text, due_date: Date.today ) }
    end
  end
end
