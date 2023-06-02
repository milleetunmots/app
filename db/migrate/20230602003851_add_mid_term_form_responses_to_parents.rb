class AddMidTermFormResponsesToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :rate, :integer
    add_column :parents, :reaction, :string
    add_column :parents, :speech, :text
  end
end
