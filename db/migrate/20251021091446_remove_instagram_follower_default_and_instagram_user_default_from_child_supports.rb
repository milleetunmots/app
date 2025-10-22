class RemoveInstagramFollowerDefaultAndInstagramUserDefaultFromChildSupports < ActiveRecord::Migration[6.1]
  def change
    change_column_default :child_supports, :instagram_follower, from: '2_no_information', to: nil
    change_column_default :child_supports, :instagram_user, from: '2_no_information', to: nil

    ChildSupport.where(instagram_follower: '2_no_information').update_all(instagram_follower: nil)
    ChildSupport.where(instagram_user: '2_no_information').update_all(instagram_user: nil)
  end
end
