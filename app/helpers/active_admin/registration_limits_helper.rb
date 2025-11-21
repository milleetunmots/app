module ActiveAdmin::RegistrationLimitsHelper

  def registration_form_select_collection
    RegistrationLink.all.map do |link|
      [
        "#{link.label} (#{link.url})",
        link.id
      ]
    end
  end
end
