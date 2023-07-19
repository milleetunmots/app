class AddAgesToBubbleModules < ActiveRecord::Migration[6.0]
  def change
    add_column :bubble_modules, :age, :string, array: true

    add_index :bubble_modules, :age, using: 'gin'
  end
end
