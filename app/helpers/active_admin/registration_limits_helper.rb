module ActiveAdmin::RegistrationLimitsHelper

  def registration_form_select_collection
    Source::REGISTRATION_LINKS.map do |registration_link|
      [
        "#{registration_link[:label]} (#{registration_link[:url]})",
        registration_link[:url]
      ]
    end
  end
end
