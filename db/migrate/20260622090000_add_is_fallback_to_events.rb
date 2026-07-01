class AddIsFallbackToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :is_fallback, :boolean, default: false, null: false
  end
end