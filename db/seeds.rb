puts "--- SEEDING DATABASE ---"

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

# Group

print "\tGroup"

5.times do
  FactoryBot.create(:group)
end

puts " ✓"

# Child
if Rails.env.development?
  postal_code = Parent::ALL_POSTAL_CODE

  print "\t20 Children"

  20.times do
    parent1 = FactoryBot.create(:parent, postal_code: postal_code.sample, phone_number: "0755802002")
    parent2 = FactoryBot.create(:parent, postal_code: postal_code.sample, phone_number: "0667945009")
    (rand(4) + 1).times do
      FactoryBot.create(
        :child,
        parent1: parent1,
        should_contact_parent1: true,
        parent2: parent2,
        should_contact_parent2: true
      )
    end
  end
  puts " ✓"
end

# Support Module
print "\tSupport Module"

FactoryBot.create(:support_module, age_ranges: ["twelve_to_seventeen"], theme: "reading", level: 1, name: "Intéresser mon enfant aux livres" )
FactoryBot.create(:support_module, age_ranges: ["twelve_to_seventeen"], theme: "games", level: 1, name: "eighteen_to_twenty_three" )
FactoryBot.create(:support_module, age_ranges: ["twenty_four_to_twenty_nine", "twenty_four_to_twenty_nine", "twenty_four_to_twenty_nine", "thirty_six_to_forty", "forty_one_to_forty_four"], theme: "anger", level: 1, name: "Parler pour mieux gérer les colères" )
FactoryBot.create(:support_module, age_ranges: ["twelve_to_seventeen", "eighteen_to_twenty_three"], theme: "screen", level: 1, name: "Occuper mon enfant sans les écrans" )
FactoryBot.create(:support_module, age_ranges: ["twelve_to_seventeen"], theme: "ride", level: 1, name: "Découvrir le monde pendant les sorties" )
FactoryBot.create(:support_module, age_ranges: ["less_than_five", "five_to_eleven"], theme: "reading", level: 1, name: "Intéresser mon enfant aux livres" )
FactoryBot.create(:support_module, age_ranges: ["five_to_eleven"], theme: "songs", level: 1, name: "Chanter avec mon bébé" )
FactoryBot.create(:support_module, age_ranges: ["five_to_eleven"], theme: "games", level: 1, name: "Jouer avec mon bébé")
FactoryBot.create(:support_module, age_ranges: ["five_to_eleven"], theme: "language", level: 1, name: "Parler avec mon bébé")
FactoryBot.create(:support_module, age_ranges: ["five_to_eleven"], theme: "bilingualism", for_bilingual: true, level: 1, name: "Parler ma langue avec mon bébé")
FactoryBot.create(:support_module, age_ranges: ["five_to_eleven"], theme: "songs", level: 2, name: "Chanter souvent avec mon bébé")
FactoryBot.create(:support_module, age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], theme: "screen", level: 2, name: "Mieux gérer les écrans avec mon enfant")
FactoryBot.create(:support_module, age_ranges: ["five_to_eleven"], theme: "screen", level: 1, name: "Occuper mon bébé sans les écrans")
FactoryBot.create(:support_module, age_ranges: ["twelve_to_seventeen", "eighteen_to_twenty_nine"], theme: "reading", level: 2, name: "Garder l'intérêt de mon enfant avec les livres")
FactoryBot.create(:support_module, name: "Chanter avec mon bébé 🎶", theme: "songs", age_ranges: ["twelve_to_seventeen"], level: 1)
FactoryBot.create(:support_module, name: "Chanter avec mon bébé 🎶", theme: "songs", age_ranges: ["eighteen_to_twenty_three", "twenty_four_to_twenty_nine", "thirty_to_thirty_five", "thirty_six_to_forty", "forty_one_to_forty_four"], level: 1)
FactoryBot.create(:support_module, name: "Chanter souvent avec mon bébé 🎶", theme: "songs", age_ranges: ["twelve_to_seventeen"], level: 2)
FactoryBot.create(:support_module, name: "Chanter souvent avec mon bébé 🎶", theme: "songs", age_ranges: ["eighteen_to_twenty_three", "twenty_four_to_twenty_nine", "thirty_to_thirty_five", "thirty_six_to_forty", "forty_one_to_forty_four"], level: 2)
FactoryBot.create(:support_module, name: "Parler plus avec mon bébé", theme: "language", age_ranges: ["five_to_eleven", "twelve_to_seventeen"], level: 2)
FactoryBot.create(:support_module, name: "Parler encore plus avec mon bébé", theme: "language", age_ranges: ["twelve_to_seventeen", "eighteen_to_twenty_three"], level: 3)
FactoryBot.create(:support_module, name: "Parler encore plus avec mon enfant", theme: "language", age_ranges: ["twenty_four_to_twenty_nine", "thirty_to_thirty_five", "thirty_six_to_forty", "forty_one_to_forty_four"], level: 3)
FactoryBot.create(:support_module, name: "Parler plusieurs langues à la maison 🏠", for_bilingual: true, theme: "bilingualism", age_ranges: ["twelve_to_seventeen", "eighteen_to_twenty_three"], level: 1)
FactoryBot.create(:support_module, name: "Parler plusieurs langues à la maison 🏠", for_bilingual: true, theme: "bilingualism", age_ranges: ["twenty_four_to_twenty_nine", "thirty_to_thirty_five", "thirty_six_to_forty", "forty_one_to_forty_four"], level: 1)
FactoryBot.create(:support_module, name: "Garder l'intérêt de mon enfant avec les livres 📚", theme: "reading", age_ranges: ["twenty_four_to_twenty_nine", "thirty_to_thirty_five", "thirty_six_to_forty", "forty_one_to_forty_four"], level: 2)
FactoryBot.create(:support_module, name: "Intéresser mon enfant aux livres", theme: "reading", age_ranges: ["twenty_four_to_twenty_nine", "thirty_to_thirty_five", "thirty_six_to_forty", "forty_one_to_forty_four"], level: 1)
FactoryBot.create(:support_module, name: "Parler dès la naissance - module unique spécial 0-...", theme: "language", age_ranges: ["less_than_five"], level: 1)
FactoryBot.create(:support_module, name: "Garder l'intérêt de mon bébé avec les livres", theme: "reading", age_ranges: ["five_to_eleven"], level: 2)

puts " ✓"
