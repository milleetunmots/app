class AddBookDeliveryLocationToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :book_delivery_location, :string
  end
end
