class AddGoalsTrackingAndNewGoals < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call2_goals_tracking, :text
    add_column :child_supports, :call3_goals_tracking, :text
    add_column :child_supports, :call4_goals_tracking, :text
    add_column :child_supports, :call5_goals_tracking, :text

    add_column :child_supports, :call2_new_goals, :text
    add_column :child_supports, :call3_new_goals, :text
    add_column :child_supports, :call4_new_goals, :text
    add_column :child_supports, :call5_new_goals, :text
  end
end
