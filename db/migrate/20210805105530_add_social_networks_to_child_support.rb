class AddSocialNetworksToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :facebook, :boolean, null: true, default: nil
    add_column :child_supports, :whatsapp, :boolean, null: true, default: nil
    add_column :child_supports, :instagram, :boolean, null: true, default: nil
  end
end
