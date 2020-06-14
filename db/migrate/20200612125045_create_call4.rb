class CreateCall4 < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call4_technical_information, :text
    add_column :child_supports, :call4_parent_actions, :text
    add_column :child_supports, :call4_language_development, :text
    add_column :child_supports, :call4_goals, :text
    add_column :child_supports, :call4_notes, :text
    add_column :child_supports, :call4_status, :string
    add_column :child_supports, :call4_status_details, :text
    add_column :child_supports, :call4_duration, :integer
    add_column :child_supports, :call4_language_awareness, :string
    add_column :child_supports, :call4_parent_progress, :string
    add_column :child_supports, :call4_sendings_benefits, :string
    add_column :child_supports, :call4_sendings_benefits_details, :text
    add_column :child_supports, :call4_reading_frequency, :string

    add_index :child_supports, :call4_language_awareness
    add_index :child_supports, :call4_parent_progress
  end
end
