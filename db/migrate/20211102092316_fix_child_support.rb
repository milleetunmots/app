class FixChildSupport < ActiveRecord::Migration[6.0]
  def change
    rename_column :child_supports, :pursuit, :will_stay_in_group
  end
end
