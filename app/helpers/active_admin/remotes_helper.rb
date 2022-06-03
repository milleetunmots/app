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

    group_ids = Group.where(name: groups).pluck(:id)
    support_ids = ChildSupport.where(call3_sendings_benefits: call3_sending_benefits).pluck(:id)

    children = Child.where(created_at: (date_start..date_end))
                    .registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)
    children = children.where(group_id: group_ids) if groups
    children = children.where(land: lands) if lands
    children = children.where(child_support_id: support_ids) if call3_sending_benefits
    children = children.where(registration_source: registration_sources) if registration_sources
    children = children.tagged_with(tags, any: true) if tags

    parent_ids = (children.pluck(:parent1_id) + children.pluck(:parent2_id)).compact

    values["redirection_url_count"] = (RedirectionUrl.where(parent_id: parent_ids).count.fdiv(parent_ids.length) ).round(2) unless parent_ids.length.zero?
    values["redirection_url_visited_count"] = (RedirectionUrlVisit.where(redirection_url_id: RedirectionUrl.where(parent_id: parent_ids)).count.fdiv(parent_ids.length)).round(2) unless parent_ids.length.zero?
    values["redirection_url_visited_rate"] = (values["redirection_url_visited_count"].fdiv(values["redirection_url_count"]) * 100).round(2) unless values["redirection_url_count"]&.zero?
    values["messages_received_count"] = (Event.where(related_type: "Parent", related_id: parent_ids).text_messages_send_by_app.count.fdiv(parent_ids.length)).round(2) unless parent_ids.length.zero?
    values["messages_sent_count"] = (Event.where(related_type: "Parent", related_id: parent_ids).text_messages_send_by_parent.count.fdiv(parent_ids.length)).round(2) unless parent_ids.length.zero?

    values
  end

end
