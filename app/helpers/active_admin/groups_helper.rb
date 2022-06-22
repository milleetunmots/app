module ActiveAdmin::GroupsHelper
  def group_select_collection
    Group.order(:id).pluck(:name)
  end

  def group_data_count(
    registration_start, registration_end,
    age_start, age_end,
    groups,
    lands,
    call3_sending_benefits,
    registration_sources,
    tags
  )
    values = {}

    children = Child.where(created_at: (registration_start.to_date...(registration_end.to_date+1.day)))
      .registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)
      .where(group_status: "active")

    if groups
      group_ids = Group.where(name: groups).pluck(:id)
      children = groups.include?("Sans cohorte") ? children.without_group.or(children.where(group_id: group_ids)) : children.where(group_id: group_ids)
    end

    children = children.where(land: lands) if lands

    if call3_sending_benefits
      support_ids = ChildSupport.where(call3_sendings_benefits: call3_sending_benefits).pluck(:id)
      children = children.where(child_support_id: support_ids)
    end

    children = children.where(registration_source: registration_sources) if registration_sources
    children = children.tagged_with(tags, any: true) if tags

    values["goal"] = 5100
    values["active_groups_count"] = Group.where("started_at < ?", DateTime.now).where("ended_at > ?", DateTime.now).count
    values["stopped_groups_count"] = Group.where("ended_at < ?", DateTime.now).count
    values["families_count"] = children.families_count
    values["children_count"] = children.count

    values
  end

end
