class UpdateChildrenLand < ActiveRecord::Migration[6.0]
  def change
    Child.where(parent1_id: get_parent_ids(45)).each { |child| child.update land: "Loiret" }
    Child.where(parent1_id: get_parent_ids(78)).each { |child| child.update land: "Yvelines" }
    Child.where(parent1_id: get_parent_ids(93)).each { |child| child.update land: "Seine-Saint-Denis" }
    Child.where(parent1_id: get_parent_ids(75)).each { |child| child.update land: "Paris" }
    Child.where(parent1_id: get_parent_ids(57)).each { |child| child.update land: "Moselle" }
  end

  private

  def get_parent_ids(postal_code)
    Parent.where("postal_code ILIKE ?", "#{postal_code}%").pluck(:id)
  end
end
