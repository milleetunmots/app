class AddCallFive < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call5_technical_information, :text
    add_column :child_supports, :call5_parent_actions, :text
    add_column :child_supports, :call5_language_development, :text
    add_column :child_supports, :call5_goals, :text
    add_column :child_supports, :call5_notes, :text
    add_column :child_supports, :call5_status, :string
    add_column :child_supports, :call5_status_details, :text
    add_column :child_supports, :call5_duration, :integer
    add_column :child_supports, :call5_language_awareness, :string
    add_column :child_supports, :call5_parent_progress, :string
    add_column :child_supports, :call5_sendings_benefits, :string
    add_column :child_supports, :call5_sendings_benefits_details, :text
    add_column :child_supports, :call5_reading_frequency, :string
    add_index :child_supports, :call5_language_awareness
    add_index :child_supports, :call5_parent_progress
  end
end
