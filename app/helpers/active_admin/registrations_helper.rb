module ActiveAdmin::RegistrationsHelper

  def registration_data_count(date_start, date_end, age_start, age_end, lands, registration_sources)
    values = {}

    children = Child.where(created_at: (date_start..date_end))
      .registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)
    children_followed = Child.group_active_between(date_start, date_end)
      .registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)

    children = children.where(registration_source: registration_sources) if registration_sources
    children = children.where(land: lands) if lands

    children_followed = children_followed.where(registration_source: registration_sources) if registration_sources
    children_followed = children_followed.where(land: lands) if lands

    values["goal"] = 4000
    values["no_popi_children_registered_or_followed_count"] = no_popi(children.or(children_followed)).count
    values["no_popi_families_registered_or_followed_count"] = no_popi(children.or(children_followed)).map(&:parent1_id).uniq.count
    values["no_popi_fathers_registered_or_followed_count"] = no_popi(children.parents.fathers.or(children_followed.parents.fathers)).map(&:id).uniq.count

    values["no_popi_children_registered"] = no_popi(children).count
    values["no_popi_families_registered"] = no_popi(children).map(&:parent1_id).uniq.count

    values["children_registered"] = children.count
    values["families_registered"] = children.map(&:parent1_id).uniq.count

    values["no_popi_rate"] = ((values["no_popi_children_registered"] * 100).fdiv(values["children_registered"])).round(2)

    values
  end

  private

  def no_popi(query)
    query.all - query.tagged_with("hors cible")
  end
end
