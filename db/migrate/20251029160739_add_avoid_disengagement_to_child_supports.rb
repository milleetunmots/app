class AddAvoidDisengagementToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :call1_avoid_disengagement_details, :text, null: true
    add_column :child_supports, :call1_avoid_disengagement_date, :datetime, null: true
    add_column :child_supports, :call2_avoid_disengagement_details, :text, null: true
    add_column :child_supports, :call2_avoid_disengagement_date, :datetime, null: true
    add_column :child_supports, :call3_avoid_disengagement_details, :text, null: true
    add_column :child_supports, :call3_avoid_disengagement_date, :datetime, null: true
  end
end
