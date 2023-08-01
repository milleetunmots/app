class AddCall0AttributesToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call0_parent_actions, :text
    add_column :child_supports, :call0_language_development, :text
    add_column :child_supports, :call0_notes, :text
    add_column :child_supports, :call0_status, :string
    add_column :child_supports, :call0_parent_progress, :string
    add_column :child_supports, :call0_duration, :integer
    add_column :child_supports, :call0_reading_frequency, :string
    add_column :child_supports, :call0_language_awareness, :string
    add_column :child_supports, :call0_goals, :text
    add_column :child_supports, :call0_sendings_benefits, :string
    add_column :child_supports, :call0_sendings_benefits_details, :text
    add_column :child_supports, :call0_technical_information, :text
    add_column :child_supports, :call0_tv_frequency, :string
    add_column :child_supports, :call0_status_details, :text
    add_index :child_supports, :call0_parent_progress
    add_index :child_supports, :call0_reading_frequency
    add_index :child_supports, :call0_tv_frequency
  end
end
