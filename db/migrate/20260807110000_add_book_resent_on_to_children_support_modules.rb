class AddBookResentOnToChildrenSupportModules < ActiveRecord::Migration[7.0]
  def change
    add_column :children_support_modules, :book_resent_on, :date
  end
end
