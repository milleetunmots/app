class RemovePresentOnFacebookAndFollowUsOnFacebookFromParents < ActiveRecord::Migration[6.1]
  def change
    remove_column :parents, :present_on_facebook
    remove_column :parents, :follow_us_on_facebook
  end
end
