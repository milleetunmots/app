class AddRcsCtaTitlesToMedia < ActiveRecord::Migration[7.0]
  def change
    add_column :media, :rcs_cta_title1, :string
    add_column :media, :rcs_cta_title2, :string
    add_column :media, :rcs_cta_title3, :string
  end
end
