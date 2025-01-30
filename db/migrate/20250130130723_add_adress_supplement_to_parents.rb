class AddAdressSupplementToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :address_supplement, :string
  end
end
