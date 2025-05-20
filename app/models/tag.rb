# == Schema Information
#
# Table name: tags
#
#  id                    :integer          not null, primary key
#  color                 :string
#  is_visible_by_callers :boolean          default(FALSE), not null
#  name                  :string
#  taggings_count        :integer          default(0)
#  created_at            :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#
class Tag < ActsAsTaggableOn::Tag

  before_validation :format_name, on: :create

  validate :no_duplicate_name

  private

  def format_name
    return unless attribute_present?('name')

    self.name = I18n.transliterate(name).downcase
  end

  def no_duplicate_name
    return unless attribute_present?('name')
    return if Tag.where('TRIM(LOWER(unaccent(name))) = ?', name.downcase).empty?

    errors.add(:base, 'Un tag avec le même nom existe déjà.')
  end
end
