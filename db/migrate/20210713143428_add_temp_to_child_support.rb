class AddTempToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :temp, :string
    ChildSupport.where("call1_books_quantity > 10").update_all(temp: "4_more_than_ten")
    ChildSupport.where("call1_books_quantity > 5 AND call1_books_quantity <= 10").update_all(temp: "3_five_to_ten")
    ChildSupport.where("call1_books_quantity > 0 AND call1_books_quantity <= 5").update_all(temp: "2_one_to_five")
    ChildSupport.where("call1_books_quantity = 0").update_all(temp: "1_none")
  end
end
