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

  validates :ean, presence: true, uniqueness: true
end
