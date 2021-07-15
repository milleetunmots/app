class RemoveCall1BooksQuantityFromChildSupport < ActiveRecord::Migration[6.0]
  def change
    remove_column :child_supports, :call1_books_quantity
  end
end
