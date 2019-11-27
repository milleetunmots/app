class AddChildSupportFields < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call2_language_awareness, :string
    add_column :child_supports, :call2_parent_progress, :string
    add_column :child_supports, :call3_language_awareness, :string
    add_column :child_supports, :call3_parent_progress, :string

    add_index :child_supports, :call2_language_awareness
    add_index :child_supports, :call2_parent_progress
    add_index :child_supports, :call3_language_awareness
    add_index :child_supports, :call3_parent_progress
  end
end
