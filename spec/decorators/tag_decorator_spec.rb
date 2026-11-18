require 'rails_helper'

RSpec.describe TagDecorator do
  describe '.text_color_for' do
    it 'écrit en blanc sur un fond foncé' do
      expect(described_class.text_color_for('#000000')).to eq(TagDecorator::LIGHT_TEXT)
      expect(described_class.text_color_for('#7b219f')).to eq(TagDecorator::LIGHT_TEXT)
    end

    it 'écrit en foncé sur un fond clair' do
      expect(described_class.text_color_for('#f0f0f0')).to eq(TagDecorator::DARK_TEXT)
      expect(described_class.text_color_for('#20d92d')).to eq(TagDecorator::DARK_TEXT)
      expect(described_class.text_color_for('#d3d624')).to eq(TagDecorator::DARK_TEXT)
    end

    it "n'écrit qu'en noir ou en blanc, quel que soit le fond" do
      colors = %w[#000000 #7b219f #f0f0f0 #20d92d #d3d624 #3596ff #ffabcc #0b4374 #e6af2e]

      expect(colors.map { |color| described_class.text_color_for(color) }.uniq - %w[#FFFFFF #000000]).to be_empty
    end

    it 'accepte la notation courte et les majuscules' do
      expect(described_class.text_color_for('#FFF')).to eq(TagDecorator::DARK_TEXT)
    end

    it 'écrit en foncé sur le fond clair par défaut quand la couleur manque ou est illisible' do
      expect(described_class.text_color_for(nil)).to eq(TagDecorator::DARK_TEXT)
      expect(described_class.text_color_for('rouge')).to eq(TagDecorator::DARK_TEXT)
    end
  end

  describe '.pill_style' do
    it 'reprend la couleur du tag en fond, avec le texte qui y contraste' do
      expect(described_class.pill_style('#f0f0f0')).to eq("background-color: #f0f0f0; color: #{TagDecorator::DARK_TEXT}")
    end

    # Même rendu que les tags du champ d'édition (cf. brand.sass) : fond $sunken, filet $line-strong
    it 'affiche un tag sans couleur comme dans le champ d’édition' do
      expect(described_class.pill_style(nil)).to eq('background-color: #F4F1E8; border-color: #C9C3B0; color: #000000')
    end

    it 'traite une couleur invalide comme une couleur absente' do
      expect(described_class.pill_style('red; position: fixed')).to eq(described_class.pill_style(nil))
    end
  end

  describe '#colored_color' do
    it 'affiche la couleur sous forme de pastille lisible, même pour un fond presque blanc' do
      tag = Tag.create!(name: 'fond-clair', color: '#f0f0f0')

      html = Capybara.string(tag.decorate.colored_color)

      expect(html).to have_css(".tag_display[style='background-color: #f0f0f0; color: #{TagDecorator::DARK_TEXT}']", text: '#f0f0f0')
    end
  end
end
