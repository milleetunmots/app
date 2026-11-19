require 'rails_helper'

# Polices de l'admin : Inter partout, titres compris, servie par l'application
# (cf. docs/brand_identity.md). Fredoka et Poppins restent sur les pages publiques et les PDF.
RSpec.describe "Polices de l'admin", type: :request do
  let(:css) { Rails.application.assets.find_asset('active_admin.css').to_s }

  it 'déclare Inter en 400, 500 et 600, servie par l’application' do
    graisses = css.scan(/@font-face\s*{[^}]*font-family:\s*['"]?Inter['"]?;[^}]*font-weight:\s*(\d{3})/).flatten
    expect(graisses).to contain_exactly('400', '500', '600')
    expect(css).not_to include('fonts.googleapis.com')
  end

  it 'met le corps de l’admin en Inter' do
    expect(css).to match(/body\s*{[^}]*font-family:\s*['"]?Inter['"]?/)
  end

  it 'met aussi les titres en Inter' do
    expect(css).to match(/#page_title[^{]*{[^}]*font-family:\s*['"]?Inter['"]?/)
  end

  it 'ne référence ni Fredoka ni Poppins hors @font-face' do
    sans_font_face = css.gsub(/@font-face\s*{[^}]*}/, '')
    expect(sans_font_face).not_to include('Poppins')
    expect(sans_font_face).not_to include('Fredoka')
  end

  # Fichiers web officiels d'Inter 4 (dossier web/ de la publication), sans hinting :
  # les TTF « bureau » sont hintés, et Windows calait alors les lettres sur la grille de
  # pixels, ce qui les rendait étirées et serrées sur un écran à 100 %.
  %w[inter-regular inter-medium inter-semibold].each do |fichier|
    it "sert #{fichier} en woff2, à la place du TTF" do
      expect(Rails.root.join("app/assets/fonts/#{fichier}.woff2")).to exist
      expect(Rails.root.join("app/assets/fonts/#{fichier}.ttf")).not_to exist
    end
  end

  it 'déclare Inter en woff2 dans les @font-face' do
    sources = css.scan(/@font-face\s*{[^}]*font-family:\s*['"]?Inter['"]?;[^}]*}/).map { |rule| rule[/src:[^;]*/] }
    expect(sources.size).to eq(3)
    expect(sources).to all(match(/inter-[a-z]+(-[0-9a-f]+)?\.woff2.*format\(['"]woff2['"]\)/))
  end

  it 'fournit la licence OFL d’Inter' do
    expect(Rails.root.join('app/assets/fonts/OFL-inter.txt').read).to include('SIL Open Font License')
  end
end
