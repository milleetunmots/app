class AddJobToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :job, :string
    add_index :parents, :job
  end
end
