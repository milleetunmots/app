class AddCallGoalsSmsToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call0_goals_sms, :text
    add_column :child_supports, :call1_goals_sms, :text
    add_column :child_supports, :call2_goals_sms, :text
    add_column :child_supports, :call3_goals_sms, :text
    add_column :child_supports, :call4_goals_sms, :text
    add_column :child_supports, :call5_goals_sms, :text
  end
end
