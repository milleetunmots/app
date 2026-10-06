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
end
