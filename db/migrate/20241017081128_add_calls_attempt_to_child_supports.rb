class AddCallsAttemptToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :call0_attempt, :string
    add_column :child_supports, :call1_attempt, :string
    add_column :child_supports, :call2_attempt, :string
    add_column :child_supports, :call3_attempt, :string
    add_column :child_supports, :call4_attempt, :string
    add_column :child_supports, :call5_attempt, :string
  end
end
