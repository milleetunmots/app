class AddCall4PreviousGoalFollowUpToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :call4_previous_goals_follow_up, :string
  end
end
