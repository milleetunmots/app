class AddTypeOfSupportToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :type_of_support, :string, default: 'with_calls'
  end
end
