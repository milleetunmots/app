module RegistrationFormHelper
  PARENT_VISUAL = { photo: 'registration/eymen.jpg', caption: ['Eymen,', '10 mois,', 'promo 2025'] }.freeze
  PRO_VISUAL = { photo: 'registration/richie.jpg', caption: ['Richie,', '19 mois,', 'promo 2025'] }.freeze
  PARTNER_LOGOS = { 2 => 'caf-logo.jpg', 6 => 'msa-logo.svg' }.freeze

  def registration_visual(registration_origin)
    visual = registration_origin.in?([3, 5]) ? PRO_VISUAL : PARENT_VISUAL
    visual.merge(partner_logo: PARTNER_LOGOS[registration_origin])
  end
end
