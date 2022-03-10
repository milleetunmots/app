module ActiveAdmin::RemotesHelper
  def group_select_collection
    Group.order(:id).pluck(:name)
  end

  def remotes_data_count(
    registration_start, registration_end,
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

    children = Child.where(created_at: (registration_start..registration_end))
      .registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)
    children = children.where(group_id: group_ids) if groups
    children = children.where(land: lands) if lands
    children = children.where(child_support_id: support_ids) if call3_sending_benefits
    children = children.where(registration_source: registration_sources) if registration_sources
    children = children.tagged_with(tags, any: true) if tags

    # values["call_response_rate"] = Group.where("started_at < ?", DateTime.now).where("ended_at > ?", DateTime.now).count
    # values["stopped_groups"] = Group.where("ended_at < ?", DateTime.now).count
    # values["children_followed"] = children.where(group_status: "active").count
    # values["families_followed"] = children.where(group_status: "active").families_count

    values
  end

end
