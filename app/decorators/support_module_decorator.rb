class SupportModuleDecorator < BaseDecorator

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
end
