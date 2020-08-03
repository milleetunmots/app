module ActiveAdmin::MediaHelper

  def medium_theme_suggestions
    Medium.pluck('DISTINCT ON (LOWER(theme)) theme').compact.sort_by(&:downcase)
  end

end
