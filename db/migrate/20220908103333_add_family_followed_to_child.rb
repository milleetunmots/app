class AddFamilyFollowedToChild < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :family_followed, :boolean, default: false
  end
end
