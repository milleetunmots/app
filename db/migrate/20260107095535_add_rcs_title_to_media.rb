class AddRcsTitleToMedia < ActiveRecord::Migration[7.0]
  def change
    add_column :media, :rcs_title1, :string, limit: 200
    add_column :media, :rcs_title2, :string, limit: 200
    add_column :media, :rcs_title3, :string, limit: 200
  end
end
