require 'rails_helper'

RSpec.describe BookDecorator do
  describe '#cover_content_link_tag' do
    it 'ne renvoie rien pour un livre sans couverture' do
      book = FactoryBot.create(:book)

      expect(book.decorate.cover_content_link_tag).to be_nil
    end

    it 'renvoie la couverture avec un lien vers les pages du livre dans un nouvel onglet' do
      book = FactoryBot.create(:book, media: FactoryBot.create(:media_image))

      html = Capybara.string(book.decorate.cover_content_link_tag(max_width: '100px'))
      link = html.find('a')

      expect(link[:href]).to eq("/admin/books/#{book.id}/read_content")
      expect(link[:target]).to eq('_blank')
      expect(link).to have_css('img[style*="max-width: 100px;"]')
    end
  end

  describe '#pages' do
    it 'liste la couverture puis les photos intérieures, avec leurs libellés' do
      book = FactoryBot.create(:book, :with_interior_photos, media: FactoryBot.create(:media_image))

      pages = book.decorate.pages

      expect(pages.pluck(:label)).to eq(['Couverture', 'Image 1', 'Image 2'])
      expect(pages.first[:source]).to eq(book.media.file)
      expect(pages.drop(1).pluck(:source)).to eq(book.interior_photos.to_a)
    end

    it "commence à l'image 1 pour un livre sans couverture" do
      book = FactoryBot.create(:book, :with_interior_photos)

      expect(book.decorate.pages.pluck(:label)).to eq(['Image 1', 'Image 2'])
    end

    it 'ne renvoie aucune page pour un livre sans image' do
      book = FactoryBot.create(:book)

      expect(book.decorate.pages).to eq([])
    end
  end
end
