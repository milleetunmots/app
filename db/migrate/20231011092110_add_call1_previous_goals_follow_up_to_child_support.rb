class AddCall1PreviousGoalsFollowUpToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call1_previous_goals_follow_up, :string
  end
end
