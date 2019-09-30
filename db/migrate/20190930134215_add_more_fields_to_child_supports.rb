class AddMoreFieldsToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call1_books_quantity, :integer
    add_column :child_supports, :call1_reading_frequency, :string
    add_index :child_supports, :call1_reading_frequency
  end
end
