namespace :child do
  desc 'Add security token to children'
  task add_security_token: :environment do
    Child.where(security_token: nil).find_each do |child|
      child.update_column(:security_token, SecureRandom.hex(16))
    end
  end
end
