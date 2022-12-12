class AddShouldContactToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :should_be_contacted, :boolean, null: false, default: true
  end
end
