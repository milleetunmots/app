class AddBookNotReceivedToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :book_not_received, :string
    add_index :child_supports, :book_not_received
  end
end
