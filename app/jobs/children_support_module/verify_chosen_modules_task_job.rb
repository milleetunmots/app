class ChildrenSupportModule
  class VerifyChosenModulesTaskJob < ApplicationJob
    def perform(group_id, verification_date)
      group = Group.includes(children: :children_support_modules).find(group_id)
      logistics_team_members = AdminUser.all_logistics_team_members
      child_support_module_links = {}

      group.children.each do |child|
        child.children_support_modules.where(support_module: nil).each do |csm|
          child_support_module_links[:"#{child.decorate.name} - #{csm.parent.decorate.name}"] = Rails.application.routes.url_helpers.edit_admin_children_support_module_url(id: csm.id)
        end
      end

      description_text = "Compléter les modules pour :"
      child_support_module_links.each do |name, link|
        description_text << "<br>#{ActionController::Base.helpers.link_to(name, link, target: '_blank', class: 'blue')}"
      end
      logistics_team_members.each { |ltm| Task.create(assignee_id: ltm.id, title: "Compléter les modules pour la cohorte \"#{group.name}\"", description: description_text, due_date: Date.today ) }
    end
  end
end
