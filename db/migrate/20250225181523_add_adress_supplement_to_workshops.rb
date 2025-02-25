class AddAdressSupplementToWorkshops < ActiveRecord::Migration[6.1]
  def change
    add_column :workshops, :address_supplement, :string
  end
end
