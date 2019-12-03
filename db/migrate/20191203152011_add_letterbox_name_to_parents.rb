class AddLetterboxNameToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :letterbox_name, :string
    Parent.update_all("letterbox_name = first_name || ' ' || last_name")
  end
end
