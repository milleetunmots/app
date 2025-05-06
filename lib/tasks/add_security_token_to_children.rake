namespace :child do
  desc 'Add security token to children'
  task add_security_token: :environment do
    Child.where(security_token: nil).find_each do |child|
      p child.id
      child.security_token = SecureRandom.hex(16)
      child.save(validate: false)
    end
  end
end
