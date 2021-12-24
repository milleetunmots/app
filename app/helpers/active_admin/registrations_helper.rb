module ActiveAdmin::RegistrationsHelper

  def data_count(
    registration_start,
    registration_end,
    age_start,
    age_end,
    registration_sources
  )
    values = {}

    values["families_count"] = Child.where(created_at: (registration_start..registration_end), registration_source: registration_sources)
      .select("DISTINCT parent1_id", "created_at", "birthdate")
      .count { |child| child.registration_months <= age_end.gsub(" mois", "").to_i && child.registration_months >= age_start.gsub(" mois", "").to_i }

    values["children_count"] = Child.where(created_at: (registration_start..registration_end), registration_source: registration_sources)
      .count { |child| child.registration_months <= age_end.gsub(" mois", "").to_i && child.registration_months >= age_start.gsub(" mois", "").to_i }


    values
  end
end
