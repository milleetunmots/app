# == Schema Information
#
# Table name: books
#
#  id         :bigint           not null, primary key
#  ean        :string           not null
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  media_id   :bigint
#
# Indexes
#
#  index_books_on_ean       (ean) UNIQUE
#  index_books_on_media_id  (media_id)
#
# Foreign Keys
#
#  fk_rails_...  (media_id => media.id)
#
class Book < ApplicationRecord

  belongs_to :media, class_name: 'Media::Image', optional: true
  has_many :support_modules, dependent: :nullify
  has_many :children_support_modules, dependent: :nullify

  # Photos intérieures rapatriées du champ Airtable « Photos intérieures ».
  # La couverture, elle, reste unique et portée par l'association media.
  has_many_attached :interior_photos

  validates :ean, presence: true, uniqueness: true, numericality: { only_numeric: true }
  validates :title, presence: true
  # Pas de `attached: true` : le champ Airtable n'est pas toujours renseigné,
  # un livre sans photo intérieure reste valide.
  validates :interior_photos, content_type: Media::Image::CONTENT_TYPES
end
