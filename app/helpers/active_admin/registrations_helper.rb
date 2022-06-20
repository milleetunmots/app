module ActiveAdmin::RegistrationsHelper

  def registration_data_count(registration_start, registration_end, age_start, age_end, groups, lands, registration_sources)
    values = {}

    children = Child.where(created_at: (registration_start.to_date...(registration_end.to_date+1.day))).registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)

    if groups
      group_ids = Group.where(name: groups).pluck(:id)
      children = groups.include?("Sans cohorte") ? children.without_group : children.where(group_id: group_ids)
    end

    children = children.where(land: lands) if lands
    children = children.where(registration_source: registration_sources) if registration_sources

    not_target_children = children.where(group_id: Group.not_target_group.pluck(:id))

    values["goal"] = 4000
    values["families_count"] = children.families_count
    values["children_count"] = children.count
    values["fathers_count"] = children.fathers_count

    values["target_families_count"] = values["families_count"] - not_target_children.families_count
    values["target_children_count"] = values["children_count"] - not_target_children.count
    values["target_fathers_count"] = values["fathers_count"] - not_target_children.fathers_count
    values["target_rate"] = ((values["target_children_count"] * 100).fdiv(values["children_count"])).round(2)

    values
  end
end
