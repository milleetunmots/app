class CreateChildrenSupportModules < ActiveRecord::Migration[6.0]
  def change
    create_table :children_support_modules do |t|
      t.references :child
      t.references :support_module
      t.references :parent

      t.timestamps
    end
  end
end
