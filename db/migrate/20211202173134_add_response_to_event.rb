class AddResponseToEvent < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :response, :string
  end
end
