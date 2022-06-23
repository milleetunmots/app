class AddSocialNetworkToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :on_facebook, :boolean
    add_column :parents, :on_whatsapp, :boolean
  end
end
