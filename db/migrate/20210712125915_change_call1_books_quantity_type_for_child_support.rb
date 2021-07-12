class ChangeCall1BooksQuantityTypeForChildSupport < ActiveRecord::Migration[6.0]
  def change
    change_column :child_supports, :call1_books_quantity, :string
  end
end
