class AddAircallDatasToParents < ActiveRecord::Migration[6.1]

  def change
    add_column :parents, :aircall_id, :string
    add_column :parents, :aircall_datas, :jsonb
  end
end
