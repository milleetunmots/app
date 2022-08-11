class AddGradeAndGradedInFranceToParent < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :grade, :string
    add_column :parents, :grade_country, :boolean
  end
end
