class AddAgeRangesToSupportModules < ActiveRecord::Migration[6.0]
  def change
    add_column :support_modules, :age_ranges, :string, array: true

    add_index :support_modules, :age_ranges, using: 'gin'
  end
end
