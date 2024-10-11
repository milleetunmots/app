class AddAircallIToParents < ActiveRecord::Migration[6.1]

  def change
    add_column :parents, :aircall_id, :string
  end
end
