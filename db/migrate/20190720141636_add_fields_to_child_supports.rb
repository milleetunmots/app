class AddFieldsToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call1_status_details, :text
    add_column :child_supports, :call2_status_details, :text
    add_column :child_supports, :call3_status_details, :text
    add_column :child_supports, :call1_duration, :string
    add_column :child_supports, :call2_duration, :string
    add_column :child_supports, :call3_duration, :string
  end
end
