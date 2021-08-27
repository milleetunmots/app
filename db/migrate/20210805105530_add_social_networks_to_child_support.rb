class AddSocialNetworksToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :present_on, :string
    add_column :child_supports, :follow_us_on, :string
  end
end
