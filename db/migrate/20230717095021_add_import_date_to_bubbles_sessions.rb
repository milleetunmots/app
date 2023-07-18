class AddImportDateToBubblesSessions < ActiveRecord::Migration[6.0]
  def change
    add_column :bubble_sessions, :import_date, :datetime
  end
end
