class AddCall2FamilyProgressAndCall2GoalsFollowUpToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call2_family_progress, :string
    add_column :child_supports, :call2_previous_goals_follow_up, :string
  end
end
