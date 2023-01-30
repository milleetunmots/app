class ChildrenSupportModule
  class VerifyChosenModulesTaskJob < ApplicationJob
    def perform(group_id, verification_date)

      group = Group.includes(children: :children_support_modules).find(group_id)
      logistics_team_members = AdminUser.all_logistics_team_members
      child_support_module_link = {}

      group.children.each do |child|
        child_support_module_link[:"#{child.decorate.name}"] = []
        child.children_support_modules.where(support_module: nil).each do |csm|
          child_support_module_link[:"#{child.decorate.name}"] << Rails.application.routes.url_helpers.edit_admin_children_support_module_url(id: csm.id)
        end
      end

      description_text = "Vérifier le choix de modules pour:"
      child_support_module_link.each do |name, link|
        next if link.empty?

        description_text << "\n- #{name} : #{link.join(", ")}"
      end
      logistics_team_members.each { |ltm| Task.create(assignee_id: ltm.id, title: "Vérification du choix de modules", description: description_text, due_date: Date.today ) }
    end
  end
end
