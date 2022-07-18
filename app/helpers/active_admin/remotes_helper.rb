module ActiveAdmin::RemotesHelper

  def remote_data_count(
    date_start, date_end,
    age_start, age_end,
    groups,
    lands,
    call3_sending_benefits,
    registration_sources,
    tags
  )
    values = {}

    children = Child.where("group_start >= ?", date_start.to_date)

    children = children.where("group_end <= ?", date_end.to_date).or(children.where(group_end: nil))
                    .registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)

    if groups
      group_ids = Group.where(name: groups).pluck(:id)
      children = children.where(group_id: group_ids)
    end

    children = children.where(land: lands) if lands

    if call3_sending_benefits
      support_ids = ChildSupport.where(call3_sendings_benefits: call3_sending_benefits).pluck(:id)
      children = children.where(child_support_id: support_ids)
    end

    children = children.where(registration_source: registration_sources) if registration_sources
    children = children.tagged_with(tags, any: true) if tags

    parent_ids = (children.pluck(:parent1_id) + children.pluck(:parent2_id)).compact

    redirection_url_ids = RedirectionUrl.where(parent_id: parent_ids).pluck(:id)

    redirection_url_sent_count = RedirectionUrlSent.where(redirection_url_id: redirection_url_ids).count

    redirection_url_unique_visited = RedirectionUrlVisit.where(redirection_url_id: RedirectionUrlSent.where(redirection_url_id: redirection_url_ids).select(:redirection_url_id)).pluck("COUNT(DISTINCT redirection_url_id)").first

    values["children_count"] = children.count
    values["parent_count"] = parent_ids.count
    values["redirection_url_sent_rate"] = (redirection_url_sent_count.fdiv(parent_ids.length) ).round(2) unless parent_ids.length.zero?
    values["redirection_url_unique_visited_rate"] = (redirection_url_unique_visited.fdiv(redirection_url_sent_count) * 100).round(2) unless redirection_url_sent_count.zero?
    values["messages_received_count"] = (Event.where(related_type: "Parent", related_id: parent_ids).text_messages_send_by_app.count.fdiv(parent_ids.length)).round(2) unless parent_ids.length.zero?
    values["messages_sent_count"] = (Event.where(related_type: "Parent", related_id: parent_ids).text_messages_send_by_parent.count.fdiv(parent_ids.length)).round(2) unless parent_ids.length.zero?

    values
  end
end