class AddSecurityTokenToChildren < ActiveRecord::Migration[6.1]
  def change
    add_column :children, :security_token, :string
  end
end
