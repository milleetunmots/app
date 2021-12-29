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
    tags)
    values = {}

    groups = Group.where(name: groups).pluck(:id)

    children = Child.where(
      created_at: (registration_start..registration_end),
      registration_source: registration_sources,
      group_id: groups,
      land: lands
    ).select { |child| child.registration_months <= age_end.gsub(" mois", "").to_i && child.registration_months >= age_start.gsub(" mois", "").to_i }


  end

end
