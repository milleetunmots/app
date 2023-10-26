class ChildSupport::VerifyAvailableModulesTaskService

  def initialize(group_id)
    @group = Group.includes(children: :child_support).find(group_id)
    @child_support_link = {}
    @logistics_team_members = AdminUser.all_logistics_team_members
    @errors = {}
  end

  def call
    @group.children.each do |child|
      unless child.child_support
        @errors["child: #{child.id}"] = "Cet enfant n'a pas de fiche de suivi"
        next
      end

      create_child_support_link(child)
    end
    Rollbar.error(@errors) if @errors.any?
    return if @child_support_link.blank?

    description_text = 'Compléter le choix de modules disponibles pour :'
    child_support_link.each { |name, link| description_text << "<br>#{ActionController::Base.helpers.link_to(name, link, target: '_blank', class: 'blue')}" }
    logistics_team_members.each { |ltm| Task.create(assignee_id: ltm.id, title: "Il manque des choix à préparer pour la cohorte \"#{group.name}\"", description: description_text, due_date: Date.today) }
    Rollbar.error(description_text)
    self
  end

  private

  def create_child_support_link(child)
    parent1_unavailbable_modules = child.child_support.parent1_available_support_module_list.nil? || child.child_support.parent1_available_support_module_list.reject(&:blank?).empty?
    parent2_unavailbable_modules = child.child_support.parent2 && (child.child_support.parent2_available_support_module_list.nil? || child.child_support.parent2_available_support_module_list.reject(&:blank?).empty?)
    unavailable_modules = parent1_unavailbable_modules || parent2_unavailbable_modules
    return unless unavailable_modules

    @child_support_link[:"#{child.decorate.name}"] = Rails.application.routes.url_helpers.edit_admin_child_support_url(id: child.child_support.id)
  end
end
