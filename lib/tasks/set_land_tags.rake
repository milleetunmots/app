# Run with rake funders:populate
namespace :set_land do
  desc 'Set land tags'
  task land_tags: :environment do
    set_land_tag("Paris_18_eme", %w[75018])
    set_land_tag("Paris_20_eme", %w[75020])
    set_land_tag("Aulnay-Sous-Bois", %w[93600])
    set_land_tag("Plaisir", %w[78570 78540 78650 78700 78710 78711 78760 78800 78820 78860 78910 78955 78610 78980 78520 78490 78420 78410 78390 78380 78330 78300 78260 78220 78210 78200 78180 78150 78140 78130 78370 78340 78310 78280 78114 78320 78450 78960 78100 78640 78850])
    set_land_tag("Trappes", %w[78190 78990])
    set_land_tag("Orleans", %w[45000 45100 45140 45160 45240 45380 45400 45430 45470 45650 45770 45800])
    set_land_tag("Montargis", %w[45110 45120 45200 45210 45220 45230,45260 45270 45290 45320 45490 45500 45520 45680 45700 49800 77460 77570])
  end

  def get_parent_ids(postal_code)
    Parent.where(postal_code: postal_code).pluck(:id)
  end

  def set_land_tag(tag, postal_codes)
    Child.where(parent1_id: get_parent_ids(postal_codes)).each do |child|
      child.land_list.add(tag)
      child.save!
    end
  end
end
