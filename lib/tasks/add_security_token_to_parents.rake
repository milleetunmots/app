namespace :parent do
  desc 'Add security token to parents'
  task add_security_token: :environment do
    Parent.where(security_token: nil).find_each do |parent|
      p parent.id
      parent.security_token = SecureRandom.hex(16)
      parent.save(validate: false)
    end
  end
end
