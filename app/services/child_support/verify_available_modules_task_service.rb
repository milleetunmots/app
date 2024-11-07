class ChildSupport::VerifyAvailableModulesTaskService

  def initialize(group_id)
    @group = Group.includes(children: :child_support).find(group_id)
    @child_support_link = {}
    @children_with_missing_child_support = []
  end

  def call
    @group.children.where(group_status: 'active').each do |child|
      @children_with_missing_child_support << child.id and next unless child.child_support
      # this child will have its status set to "stopped" when SelectModuleJob runs, we can ignore
      next if child.birthdate < 36.months.ago

      create_child_support_link(child)
    end

    Rollbar.error(
      "Certains enfants de la cohorte #{@group.id} n'ont pas de fiche de suivi",
      children: @children_with_missing_child_support,
      source: 'ChildSupport::VerifyAvailableModulesTaskService'
    ) if @children_with_missing_child_support.any?

    return if @child_support_link.blank?

    description_text = 'Compléter le choix de modules disponibles pour :'
    @child_support_link.each { |name, link| description_text << "<br>#{ActionController::Base.helpers.link_to(name, link, target: '_blank', class: 'blue')}" }
    Task::CreateAutomaticTaskService.new(
      title: "Il manque des choix à préparer pour la cohorte \"#{@group.name}\"",
      description: description_text
      ).call
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
