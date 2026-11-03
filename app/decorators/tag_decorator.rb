class TagDecorator < BaseDecorator

  # Fond d'un tag sans couleur : gris clair ($line-strong de admin/_variables.sass), visible
  # aussi sur une ligne survolée, plutôt qu'un aplat foncé
  DEFAULT_BACKGROUND = '#D2CFC2'.freeze
  # Texte d'une pastille de tag : blanc, ou encre de la charte ($ink) sur un fond clair
  LIGHT_TEXT = '#FFFFFF'.freeze
  DARK_TEXT = '#2B2B2B'.freeze

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
      background = valid_background(background)
      "background-color: #{background}; color: #{text_color_for(background)}"
    end

    private

    # La couleur finit dans un attribut style : seule une couleur hexadécimale passe
    def valid_background(color)
      color.to_s.strip.match?(HEX_COLOR) ? color.to_s.strip : DEFAULT_BACKGROUND
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
