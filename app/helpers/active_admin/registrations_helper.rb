module ActiveAdmin::RegistrationsHelper

  def families_data_count(
    birthdate_start,
    birthdate_end,
    registration_date_start,
    registration_date_end
  )
    birthdate_start = Date.strptime(birthdate_start.to_s, "%Y-%m-%d")
    birthdate_end = Date.strptime(birthdate_end.to_s, "%Y-%m-%d")
    Child.where(birthdate: birthdate_start..birthdate_end)
      .where(created_at: registration_date_start..registration_date_end)
      .families_count
  end

  def children_data_count(
    birthdate_start,
    birthdate_end,
    registration_date_start,
    registration_date_end
  )
    birthdate_start = Date.strptime(birthdate_start.to_s, "%Y-%m-%d")
    birthdate_end = Date.strptime(birthdate_end.to_s, "%Y-%m-%d")
    Child.where(birthdate: birthdate_start..birthdate_end)
      .where(created_at: registration_date_start..registration_date_end)
      .count
  end

  def fathers_data_count(
    birthdate_start,
    birthdate_end,
    registration_date_start,
    registration_date_end
  )
    birthdate_start = Date.strptime(birthdate_start.to_s, "%Y-%m-%d")
    birthdate_end = Date.strptime(birthdate_end.to_s, "%Y-%m-%d")
    Child.where(birthdate: birthdate_start..birthdate_end)
      .where(created_at: registration_date_start..registration_date_end)
      .fathers_count
  end

end
