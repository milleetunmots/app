class AddFamilyFollowedToChild < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :family_followed, :boolean, default: false
  end
end
