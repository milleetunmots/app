# Run with rake funders:populate
namespace :set_land do
  desc 'Set land tags'
  task land_tags: :environment do
    set_tag("Paris_18_eme", %w[75018])
    set_tag("Paris_20_eme", %w[75020])
    set_tag("Plaisir", %w[78370 78340 78310 78990 78280 78114 78320 78450 78960 78100 78640 78850])
    set_tag("Trappes", %w[78190 78180 78280 78310 78610 78960])
    set_tag("Les Clayes Sous Bois", %w[78340])
    set_tag("Coignière, Maurepas", %w[78310])
    set_tag("Elancourt", %w[78990])
    set_tag("Guyancourt", %w[78280])
    set_tag("Montigny le bretonneux", %w[78180])
    set_tag("La verrière", %w[78320])
    set_tag("Villepreux", %w[78450])
    set_tag("Voisin le Bretonneux", %w[78960])
    set_tag("Aulnay-Sous-Bois", %w[93600])
    set_tag("Orleans", %w[45000 45100 45140 45160 45240 45380 45400 45430 45470 45650 45770 45800])
    set_tag("Montargis", %w[45110 45120 45200 45210 45220 45230,45260 45270 45290 45320 45490 45500 45520 45680 45700 49800 77460 77570])
  end

  def set_tag(tag, postal_codes)
    Parent.where(postal_code: postal_codes).each do |parent|
      parent.family.tag_list.add(tag)
      parent.family.save
    end
  end
end
