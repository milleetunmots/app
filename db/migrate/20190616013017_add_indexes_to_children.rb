class AddIndexesToChildren < ActiveRecord::Migration[6.0]
  def change
    add_index :children, :birthdate
    add_index :children, :gender
  end
end
