class AddResponseToEvent < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :parent_response, :string
  end
end
