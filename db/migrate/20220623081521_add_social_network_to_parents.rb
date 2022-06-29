class AddSocialNetworkToParents < ActiveRecord::Migration[6.0]
  def up
    add_column :parents, :present_on_facebook, :boolean
    add_column :parents, :present_on_whatsapp, :boolean
    add_column :parents, :follow_us_on_whatsapp, :boolean
    add_column :parents, :follow_us_on_facebook, :boolean
  end

  def down
    remove_column :parents, :on_facebook
    remove_column :parents, :on_whatsapp
  end
end
