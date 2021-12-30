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

    group_ids = Group.where(name: groups).pluck(:id)
    support_ids = ChildSupport.where(call3_sendings_benefits: call3_sending_benefits).pluck(:id)

    children = Child.where(
      created_at: (registration_start..registration_end),
      registration_source: registration_sources,
      land: lands
    )
    children = children.where(group_id: group_ids) if groups
    children = children.where(child_support_id: support_ids) if call3_sending_benefits

    children = children.tagged_with(tags) if tags

    children = children.select { |child| child.registration_months <= age_end.gsub(" mois", "").to_i && child.registration_months >= age_start.gsub(" mois", "").to_i }


    values["goal"] = 4000
    values["active_groups_count"] = Group.where("started_at < ?", DateTime.now).where("ended_at > ?", DateTime.now).count
    values["stopped_groups_count"] = Group.where("ended_at < ?", DateTime.now).count
    values["families_count"] = children.map { |item| item.parent1_id }.uniq.count
    values["children_count"] = children.count

    values
  end

end
