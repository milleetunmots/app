class AddBookToChildrenSupportModules < ActiveRecord::Migration[6.1]
  def change
    add_reference :children_support_modules, :book, foreign_key: true
  end
end
