class AddAvoidDisengagementToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :avoid_disengagement, :boolean, null: false, default: false
    add_column :child_supports, :avoid_disengagement_details, :text, null: true
    add_column :child_supports, :avoid_disengagement_date, :datetime, null: true
  end
end
