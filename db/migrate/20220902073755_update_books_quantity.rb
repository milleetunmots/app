class UpdateBooksQuantity < ActiveRecord::Migration[6.0]
  def change
    ChildSupport.where(books_quantity: '2_one_to_five').update_all(books_quantity: '2_three_or_less')
    ChildSupport.where(books_quantity: '3_five_to_ten').update_all(books_quantity: '3_between_four_and_ten')
  end
end
