module ActiveAdmin::RegistrationsHelper

  def registration_data_count(registration_start, registration_end, age_start, age_end, lands, registration_sources)
    values = {}

    children = Child.where(created_at: (registration_start..registration_end)).registration_months_between(age_start.gsub(" mois", "").to_i, age_end.gsub(" mois", "").to_i)
    children = children.where(registration_source: registration_sources) if registration_sources
    children = children.where(land: lands) if lands

    values["goal"] = 4000
    values["families_count"] = children.families_count
    values["children_count"] = children.count
    values["fathers_count"] = children.fathers_count
    values["no_popi_families_count"] = values["families_count"] - children.tagged_with("hors cible").families_count
    values["no_popi_children_count"] = values["children_count"] - children.tagged_with("hors cible").count
    values["no_popi_fathers_count"] = values["fathers_count"] - children.tagged_with("hors cible").popi_fathers_count

    values
  end
end
