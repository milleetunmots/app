module ActiveAdmin::RegistrationsHelper

  def data_count(registration_start, registration_end, age_start, age_end, registration_sources)
    values = {}

    popi_children = Child.tagged_with("hors cible").where(created_at: (registration_start..registration_end), registration_source: registration_sources)
                    .select { |child| child.registration_months <= age_end.gsub(" mois", "").to_i && child.registration_months >= age_start.gsub(" mois", "").to_i }

    children = Child.where(created_at: (registration_start..registration_end), registration_source: registration_sources)
      .select { |child| child.registration_months <= age_end.gsub(" mois", "").to_i && child.registration_months >= age_start.gsub(" mois", "").to_i }

    values["goal"] = 4000

    values["families_count"] = children.map { |item| item.parent1_id }.uniq.count
    values["children_count"] = children.count
    values["fathers_count"] = Parent.where(id: (children.map(&:parent1_id) + children.map(&:parent2_id)).compact.uniq).fathers.count
    values["no_popi_families_count"] = values["families_count"] - popi_children.map { |item| item.parent1_id }.uniq.count
    values["no_popi_children_count"] = values["children_count"] - popi_children.count
    values["no_popi_fathers_count"] = values["fathers_count"] - Parent.where(id: (popi_children.map(&:parent1_id) + popi_children.map(&:parent2_id)).compact.uniq).fathers.count

    values
  end
end
