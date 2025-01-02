class AddOrderToQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column :questions, :order, :integer, null: false
  end
end
