class AddPhoneNumberNationalToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :phone_number_national, :string
    Parent.find_each(&:save!)

    add_index :parents, :email
    add_index :parents, :gender
    add_index :parents, :first_name
    add_index :parents, :last_name
    add_index :parents, :phone_number_national
    add_index :parents, :address
    add_index :parents, :postal_code
    add_index :parents, :city_name
  end
end
