class AddCall0GoalSentToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :call0_goal_sent, :string
  end
end
