class RemovePresentOnAndFollowUsOnFromChildSupport < ActiveRecord::Migration[6.0]
  def change
    remove_column :child_supports, :present_on, :string
    remove_column :child_supports, :follow_us_on, :string
  end
end
