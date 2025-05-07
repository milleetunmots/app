class AddSecurityTokenToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :security_token, :string
  end
end
