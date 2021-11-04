class AddPostalCodeToEvent < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :postal_code, :string
  end
end
