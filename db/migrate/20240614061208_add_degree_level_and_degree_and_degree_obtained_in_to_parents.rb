class AddDegreeLevelAndDegreeAndDegreeObtainedInToParents < ActiveRecord::Migration[6.1]
  def change
    change_table :parents, bulk: true do |t|
      t.string :degree_level_at_registration
      t.string :degree_country_at_registration
    end
  end
end
