class AddInstagramFollowerAndInstagramUserToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :instagram_follower, :string, default: '2_no_information'
    add_column :child_supports, :instagram_user, :string, default: '2_no_information'
  end
end
