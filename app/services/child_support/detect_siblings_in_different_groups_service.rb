class ChildSupport::DetectSiblingsInDifferentGroupsService

  def initialize
    @child_support_link = {}
    @child_support_ids = []
  end

  def call
    @child_support_ids = ChildSupport.kept
                                     .joins(:children)
                                     .where(children: { group_status: 'active', discarded_at: nil })
                                     .group('child_supports.id')
                                     .having('COUNT(DISTINCT children.group_id) > 1')
                                     .pluck('child_supports.id')

    return self if @child_support_ids.blank?

    @child_support_ids.each { |id| build_child_support_link(id) }

    description_text = 'Les fiches de suivi suivantes ont des enfants actifs répartis dans des cohortes différentes :<br>'
    @child_support_link.each { |name, link| description_text << "<br>#{ActionController::Base.helpers.link_to(name, link, target: '_blank', class: 'blue')}" }

    Task::CreateAutomaticTaskService.new(
      title: 'Des fratries actives sont réparties dans des cohortes différentes',
      description: description_text
    ).call

    self
  end

  private

  def build_child_support_link(child_support_id)
    child_support = ChildSupport.find(child_support_id)
    name = "#{child_support.current_child&.first_name} #{child_support.current_child&.last_name}".strip
    name = "Fiche ##{child_support_id}" if name.blank?
    link = Rails.application.routes.url_helpers.edit_admin_child_support_url(id: child_support_id)
    @child_support_link[name] = link
  end
end
