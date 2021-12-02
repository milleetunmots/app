module Data::RegistrationHelper

  filter = {
    birth_year: 0,
    registration_year: 0,
    registration_source: "",
    registration_months_range: ""
  }
  def all_registration
    Child.all.count
  end
end
