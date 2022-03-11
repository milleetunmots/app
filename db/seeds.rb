puts "--- SEEDING DATABASE ---"

POSTAL_CODES = [75018, 75020, 78370, 78190, 78340, 78310, 78990, 78280, 78180, 78320, 78450, 78960, 93600, 45000, 45100, 45140, 45160, 45240, 45380, 45400, 45430, 45470, 45650, 45770, 45800, 45110, 45120, 45200, 45210, 45220, 45230, 45260, 45270, 45290, 45320, 45490, 45500, 45520, 45680, 45700, 49800, 77460, 77570]
PARENTS = []

# AdminUser

puts "\tAdminUser"

print "\t\tadmin@example.com"
AdminUser.create!(user_role: 'super_admin', name: 'Admin', email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?
puts " ✓"

# MediaFolder

puts "\tMediaFolder"

print "\t\tCBFD"
cbfd = MediaFolder.create!(name: 'CBFD')
puts " ✓"

print "\t\tCBFD/Good"
good = MediaFolder.create!(name: 'Good', parent: cbfd)
puts " ✓"

print "\t\tCBFD/Evil"
evil = MediaFolder.create!(name: 'Evil', parent: cbfd)
puts " ✓"

print "\t\tSMS"
sms = MediaFolder.create!(name: 'SMS')
puts " ✓"

print "\t\tVidéos"
videos = MediaFolder.create!(name: 'Vidéos')
puts " ✓"

# Media::Image
#
# puts "\tMedia::Image"
#
# puts "\tMedia::Image"
# goods = []
# Dir.glob('db/seed/img/cbfd/good/*.jpg').each do |path|
#   filename = File.basename(path)
#   print "\t\tCBFD/Good/#{filename}"
#   image = Media::Image.new(
#     folder: good,
#     name: filename.gsub('.jpg', '').titlecase,
#     tag_list: ['cbfd', 'good']
#   )
#   image.file.attach(
#     io: File.open(path),
#     filename: filename,
#     content_type: 'image/jpg'
#   )
#   image.save!
#   goods << image
#   puts " ✓"
# end
#
# evils = []
# Dir.glob('db/seed/img/cbfd/evil/*.jpg').each do |path|
#   filename = File.basename(path)
#   print "\t\tCBFD/Evil/#{filename}"
#   image = Media::Image.new(
#     folder: evil,
#     name: filename.gsub('.jpg', '').titlecase,
#     tag_list: ['cbfd', 'evil']
#   )
#   image.file.attach(
#     io: File.open(path),
#     filename: filename,
#     content_type: 'image/jpg'
#   )
#   image.save!
#   evils << image
#   puts " ✓"
# end

# Media::Video

# puts "\tMedia::Video"
#
# print "\t\tBrooklyn"
# Media::Video.create!(
#   name: 'Brooklyn',
#   url: 'https://youtu.be/p4AH_WQVz10'
# )
# puts " ✓"
#
# print "\t\tChrono Trigger"
# Media::Video.create!(
#   name: 'Chrono Trigger',
#   url: 'https://youtu.be/aqgm9rBjEH4'
# )
# puts " ✓"

# Media::TextMessagesBundle

puts "\tMedia::TextMessagesBundle"

print "\t\tBienvenue"
Media::TextMessagesBundle.create!(
  folder: sms,
  name: 'Bienvenue',
  body1: 'Bonjour !'
)
puts " ✓"
#
# print "\t\tLes gentils"
# Media::TextMessagesBundle.create!(
#   folder: sms,
#   name: 'Les gentils',
#   body1: goods[0].name,
#   image1: goods[0],
#   body2: goods[1].name,
#   image2: goods[1],
#   body3: goods[2].name,
#   image3: goods[2]
# )
# puts " ✓"
#
# print "\t\tLes méchants"
# Media::TextMessagesBundle.create!(
#   folder: sms,
#   name: 'Les méchants',
#   body1: evils[0].name,
#   image1: evils[0],
#   body2: evils[1].name,
#   image2: evils[1],
#   body3: evils[2].name,
#   image3: evils[2]
# )
# puts " ✓"
#
# Father
print "\t50 Parents"
50.times do
  parent = FactoryBot.create(:parent, postal_code: POSTAL_CODES.sample)
  PARENTS << parent
end
puts " ✓"

# Child

print "\t50 Children"

50.times do
  created_date = Faker::Date.backward(days: 120)
  child = FactoryBot.create(:child, parent1: PARENTS.sample, birthdate: created_date.prev_month((rand * 10).to_i))
  child.update_column(:created_at, created_date)
end

puts " ✓"
