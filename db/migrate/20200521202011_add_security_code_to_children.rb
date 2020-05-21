class AddSecurityCodeToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :security_code, :string
    Child.find_each do |child|
      child.security_code = SecureRandom.hex(1)
      child.save!
    end
  end
end
