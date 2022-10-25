class AddFacebookNameToParent < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :facebook_name, :string
  end
end
