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
require 'rails_helper'

RSpec.describe Book do
  # Les photos intérieures viennent du champ Airtable « Photos intérieures »,
  # qui en contient plusieurs par livre — contrairement à la couverture, unique
  # et portée par l'association media.
  describe 'interior photos' do
    def seed_image(name)
      Rails.root.join('db', 'seed', 'img', 'cbfd', 'good', name)
    end

    def attach(book, name, content_type: 'image/jpeg', io: nil)
      book.interior_photos.attach(
        io: io || File.open(seed_image(name)),
        filename: name,
        content_type: content_type
      )
    end

    it 'holds several interior photos at once' do
      book = FactoryBot.create(:book)

      attach(book, 'birdy.jpg')
      attach(book, 'conker.jpg')

      expect(book.reload.interior_photos.map { |photo| photo.blob.filename.to_s })
        .to contain_exactly('birdy.jpg', 'conker.jpg')
    end

    it 'rejects a file that is not an image' do
      book = FactoryBot.build(:book)

      attach(book, 'notes.txt', content_type: 'text/plain', io: StringIO.new('pas une image'))

      expect(book).not_to be_valid
      expect(book.errors[:interior_photos]).to be_present
    end

    # Le champ Airtable n'est pas toujours renseigné : un livre sans photo
    # intérieure reste un livre valide.
    it 'stays valid without any interior photo' do
      book = FactoryBot.build(:book)

      expect(book.interior_photos).to be_empty
      expect(book).to be_valid
    end

    it 'exposes a factory trait attaching interior photos' do
      book = FactoryBot.create(:book, :with_interior_photos)

      expect(book.interior_photos.count).to eq(2)
      expect(book.interior_photos.first.blob).to be_present
    end
  end
end
