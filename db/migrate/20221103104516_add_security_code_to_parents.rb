class AddSecurityCodeToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :security_code, :string
    Parent.find_each do |parent|
      parent.security_code = SecureRandom.hex(1)
      parent.save!
    end
  end
end
