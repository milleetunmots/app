class Tag < ActsAsTaggableOn::Tag

  before_validation :format_name

  private

  def format_name
    if attribute_present?("name")
      self.name = I18n.transliterate(self.name).downcase
    end
  end
end
