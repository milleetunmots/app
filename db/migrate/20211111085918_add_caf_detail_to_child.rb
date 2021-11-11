class AddCafDetailToChild < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :caf_detail, :string
  end
end
