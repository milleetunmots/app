class ChangeCall1BooksQuantityTypeForChildSupport < ActiveRecord::Migration[6.0]
  def up
    change_column :child_supports, :call1_books_quantity, :string, using: 'call1_books_quantity::integer'
  end

  def down
    change_column :child_supports, :call1_books_quantity, :integer
  end
end
