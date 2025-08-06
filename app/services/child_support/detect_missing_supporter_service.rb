class ChildSupport::DetectMissingSupporterService
  def initialize
    @child_support_link = {}
    @child_supports_without_supporter = []
  end

  def call
    @child_supports_without_supporter = ChildSupport.without_supporter_in_active_programmed_group.ids
    @child_supports_without_supporter.each do |child_support_id|
      create_child_support_link(child_support_id)
    end

    return self if @child_support_link.blank?

    description_text = "Les fiches suivantes n'ont pas d'accompagnante alors qu'au moins un enfant doit être suivi :<br>"
    @child_support_link.each { |name, link| description_text << "<br>#{ActionController::Base.helpers.link_to(name, link, target: '_blank', class: 'blue')}" }
    Task::CreateAutomaticTaskService.new(
      title: "Des fiches de suivi n'ont pas d'accompagnante",
      description: description_text
    ).call

    Rollbar.error(
      "Certaines fiches de suivi n'ont pas d'accompagnante",
      child_supports: @child_supports_without_supporter,
      source: 'ChildSupport::DetectMissingSupporterService'
    )
    self
  end

  private

  def create_child_support_link(child_support_id)
    link = Rails.application.routes.url_helpers.edit_admin_child_support_url(id: child_support_id)
    @child_support_link[:"#{link}"] = link
  end
end
