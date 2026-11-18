# Mise en page du texte des étiquettes (pdf.sass) : combien de lignes un texte occupe une
# fois coupé à la largeur de l'étiquette. Les largeurs sont celles des glyphes de Poppins
# Regular et de Fredoka Bold, tirées des TTF d'app/assets/fonts dans
# config/label_font_metrics.json (en em, par caractère ; « default » : le glyphe le plus
# large, pour un caractère absent de la police). À régénérer si ces polices changent.
#
# La coupure suit celle du navigateur : aux espaces et après les traits d'union ; un mot
# plus long que la ligne est coupé n'importe où (word-break: break-word dans pdf.sass).
# Compter les caractères ne suffisait pas : un nom de quatre mots prenait une ligne de
# plus que prévu et l'étiquette débordait.
module LabelTextLayout
  METRICS = JSON.parse(Rails.root.join('config/label_font_metrics.json').read).freeze

  # Marge sur les largeurs mesurées : crénage et arrondis du rendu de wkhtmltopdf
  SAFETY_FACTOR = 1.03

  module_function

  def width_em(text, font)
    metrics = METRICS.fetch(font)
    text.to_s.each_char.sum { |char| metrics['widths'].fetch(char, metrics['default']) } * SAFETY_FACTOR
  end

  def rows(text, font:, size_pt:, width_pt:)
    line_max = width_pt / size_pt
    space = width_em(' ', font)
    rows = 1
    line = nil

    text.to_s.split.each do |word|
      word.split(/(?<=-)/).each_with_index do |segment, index|
        segment_width = width_em(segment, font)
        gap = line && index.zero? ? space : 0

        if line.nil?
          line = 0
        elsif line + gap + segment_width <= line_max
          line += gap + segment_width
          next
        else
          rows += 1
          line = 0
        end

        extra_rows, line = start_line(segment_width, line_max)
        rows += extra_rows
      end
    end

    rows
  end

  # Segment posé en début de ligne : plus long que la ligne, il se coupe n'importe où.
  # [lignes ajoutées, largeur occupée sur la dernière]
  def start_line(segment_width, line_max)
    extra_rows = [(segment_width / line_max).ceil - 1, 0].max
    [extra_rows, segment_width - (extra_rows * line_max)]
  end
end
