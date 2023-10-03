class AddCall1GoalsTrakingToChildSupport < ActiveRecord::Migration[6.0]

  def change
    add_column :child_supports, :call1_goals_tracking, :text
  end
end
