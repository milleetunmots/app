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

    it 'remplace une couleur absente ou invalide par le fond par défaut' do
      expect(described_class.pill_style(nil)).to eq("background-color: #{TagDecorator::DEFAULT_BACKGROUND}; color: #{TagDecorator::DARK_TEXT}")
      expect(described_class.pill_style('red; position: fixed')).to eq("background-color: #{TagDecorator::DEFAULT_BACKGROUND}; color: #{TagDecorator::DARK_TEXT}")
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
