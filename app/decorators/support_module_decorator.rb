class SupportModuleDecorator < BaseDecorator

  # Les emojis sont saisis directement dans le nom du module en base : on les
  # retire à l'affichage sans toucher aux données
  EMOJI_PATTERN = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{20E3}]/

  def admin_link(options = {})
    super(options.merge(label: "#{model.name} #{model.decorate.display_age_ranges}"))
  end

  def ages
    SupportModule.human_attribute_name("ages.#{model.ages}")
  end

  def display_theme
    return if model.theme.nil?

    SupportModule.human_attribute_name("theme.#{model.theme}")
  end

  def display_age_ranges
    return if model.age_ranges.blank?

    model.age_ranges.reject(&:blank?).map { |ar| SupportModule.human_attribute_name("age_range.#{ar}") }.join(' / ')
  end

  def picture_tag(options = {})
    return nil unless model.picture.attached?

    options.merge!(source: model.picture)
    h.image_tag_with_max_size **options
  end

  def name_with_tags
    "#{object.name} #{object.tag_list.join(' ')}"
  end

  def name_without_emoji
    model.name.to_s.gsub(EMOJI_PATTERN, '').squeeze(' ').strip
  end

  # « 12 - 17 mois » -> « 12-17 » : indication discrète à côté du nom du module,
  # dérivée de age_ranges (et non des tags, qui sont filtrés selon le rôle).
  # « mois » n'est retiré qu'en fin de tranche, pour ne pas abîmer les libellés
  # de la forme « 23 mois et plus »
  def short_age_ranges
    display_age_ranges&.gsub(/(\d) - (\d)/, '\1-\2')&.gsub(%r{ mois(?= /|\z)}, '')
  end

  def airtable_folder_url
    Airtables::SupportModuleContent.record_url_for(model)
  end
end
