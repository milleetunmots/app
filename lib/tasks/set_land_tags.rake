# Run with rake funders:populate
namespace :set_land do
  desc 'Set land tags'
  task land_tags: :environment do
    Child.where(parent1_id: get_parent_ids(%w[75018])).each do |child|
      child.tag_list.add("Paris_18_eme")
      child.save!
    end
    Child.where(parent1_id: get_parent_ids(%w[75020])).each do |child|
      child.tag_list.add("Paris_20_eme")
      child.save!
    end
    Child.where(parent1_id: get_parent_ids(%w[93600])).each do |child|
      child.tag_list.add("Aulnay-Sous-Bois")
      child.save!
    end
    Child.where(parent1_id: get_parent_ids(%w[45000 45100 45140 45160 45240 45380 45400 45430 45470 45650 45770 45800])).each do |child|
      child.tag_list.add("Orleans")
      child.save!
    end
    Child.where(parent1_id: get_parent_ids(%w[45110 45120 45200 45210 45220 45230,45260 45270 45290 45320 45490 45500 45520 45680 45700 49800 77460 77570])).each do |child|
      child.tag_list.add("Montargis")
      child.save!
    end
  end

  def get_parent_ids(postal_code)
    Parent.where(postal_code: postal_code).pluck(:id)
  end
end
