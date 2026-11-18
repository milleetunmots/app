class TagDecorator < BaseDecorator

  # Tag sans couleur : comme dans le champ d'édition (cf. brand.sass), fond $sunken et
  # filet $line-strong de admin/_variables.sass
  DEFAULT_BACKGROUND = '#F4F1E8'.freeze
  DEFAULT_BORDER = '#C9C3B0'.freeze
  # Texte d'une pastille de tag : noir ou blanc seulement, quel que soit le fond ; une
  # troisième encre (marine) rendait la liste des tags trop bariolée
  LIGHT_TEXT = '#FFFFFF'.freeze
  DARK_TEXT = '#000000'.freeze

  HEX_COLOR = /\A#(\h{3}|\h{6})\z/

  class << self

    # La couleur d'un tag est choisie librement (sélecteur de couleur) : le texte
    # prend celle des deux encres qui contraste le plus avec le fond (WCAG 2.x)
    def text_color_for(background)
      background = valid_background(background)
      background_luminance = relative_luminance(background)

      [LIGHT_TEXT, DARK_TEXT].max_by { |text| contrast_ratio(relative_luminance(text), background_luminance) }
    end

    def pill_style(background)
      return "background-color: #{DEFAULT_BACKGROUND}; border-color: #{DEFAULT_BORDER}; color: #{DARK_TEXT}" unless valid?(background)

      "background-color: #{background.strip}; color: #{text_color_for(background)}"
    end

    private

    # La couleur finit dans un attribut style : seule une couleur hexadécimale passe
    def valid_background(color)
      valid?(color) ? color.to_s.strip : DEFAULT_BACKGROUND
    end

    def valid?(color)
      color.to_s.strip.match?(HEX_COLOR)
    end

    def relative_luminance(hex)
      digits = hex.delete('#')
      digits = digits.chars.map { |digit| digit * 2 }.join if digits.length == 3
      red, green, blue = digits.scan(/../).map do |channel|
        value = channel.hex / 255.0
        value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
      end

      (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    end

    def contrast_ratio(luminance_a, luminance_b)
      lighter, darker = [luminance_a, luminance_b].minmax.reverse
      (lighter + 0.05) / (darker + 0.05)
    end
  end

  # La couleur telle que le tag s'affichera, plutôt qu'un code écrit dans sa propre
  # couleur (illisible pour un fond presque blanc)
  def colored_color
    return if model.color.blank?

    h.content_tag :span, model.color, class: 'tag_display', style: self.class.pill_style(model.color)
  end

  def as_autocomplete_result
    h.content_tag :div, class: 'tag-autocomplete' do
      h.content_tag :div, class: :name do
        name
      end
    end
  end

  def icon_class
    :tag
  end
end
