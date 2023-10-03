puts '--- SEEDING DATABASE ---'

# AdminUser

puts "\tAdminUser"

print "\t\tadmin@example.com"
AdminUser.create!(user_role: 'super_admin', name: 'Admin', email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?
puts ' ✓'

# MediaFolder

# puts "\tMediaFolder"

# print "\t\tCBFD"
# cbfd = MediaFolder.create!(name: 'CBFD')
# puts ' ✓'
#
# print "\t\tCBFD/Good"
# good = MediaFolder.create!(name: 'Good', parent: cbfd)
# puts ' ✓'
#
# print "\t\tCBFD/Evil"
# evil = MediaFolder.create!(name: 'Evil', parent: cbfd)
# puts ' ✓'

# print "\t\tSMS"
# sms = MediaFolder.create!(name: 'SMS')
# puts ' ✓'
#
# print "\t\tVidéos"
# videos = MediaFolder.create!(name: 'Vidéos')
# puts ' ✓'

# Media::Image
# puts "\tMedia::Image"
# goods = []
# Dir.glob('db/seed/img/cbfd/good/*.jpg').each do |path|
#   filename = File.basename(path)
#   print "\t\tCBFD/Good/#{filename}"
#   image = Media::Image.new(
#     folder: good,
#     name: filename.gsub('.jpg', '').titlecase,
#     tag_list: %w[cbfd good]
#   )
#   image.file.attach(
#     io: File.open(path),
#     filename: filename,
#     content_type: 'image/jpg'
#   )
#   image.save!
#   goods << image
#   puts ' ✓'
# end

# evils = []
# Dir.glob('db/seed/img/cbfd/evil/*.jpg').each do |path|
#   filename = File.basename(path)
#   print "\t\tCBFD/Evil/#{filename}"
#   image = Media::Image.new(
#     folder: evil,
#     name: filename.gsub('.jpg', '').titlecase,
#     tag_list: %w[cbfd evil]
#   )
#   image.file.attach(
#     io: File.open(path),
#     filename: filename,
#     content_type: 'image/jpg'
#   )
#   image.save!
#   evils << image
#   puts ' ✓'
# end

# Media::Video
# videos = []
#
# puts "\tMedia::Video"
#
# print "\t\tBrooklyn"
# videos << Media::Video.create!(
#   name: 'Brooklyn',
#   url: 'https://youtu.be/p4AH_WQVz10'
# )
# puts ' ✓'

# print "\t\tChrono Trigger"
# videos << Media::Video.create!(
#   name: 'Chrono Trigger',
#   url: 'https://youtu.be/aqgm9rBjEH4'
# )
# puts ' ✓'

# Media::TextMessagesBundle
#
# puts "\tMedia::TextMessagesBundle"
#
# print "\t\tSemaine 1"
# week_one = FactoryBot.create(:support_module_week,
#                              position: 1,
#                              medium: Media::TextMessagesBundle.create!(
#                                folder: sms,
#                                name: 'Semaine 1',
#                                body1: 'Semaine 1, message 1 ! {URL}',
#                                link1: videos[rand(0..1)],
#                                body2: 'Semaine 1, message 2 !',
#                                link2: videos[rand(0..1)],
#                                body3: 'Semaine 1, message 3 !',
#                                link3: videos[rand(0..1)]
#                              ))
# puts ' ✓'

# print "\t\tSemaine 1 additional"
# week_one.additional_medium = Media::TextMessagesBundle.create!(
#   folder: sms,
#   name: 'Semaine 1 additional',
#   body1: 'Semaine 1, message 4 !'
# )
# week_one.save
# puts ' ✓'

# print "\t\tSemaine 2"
# week_two = FactoryBot.create(:support_module_week,
#                              position: 2,
#                              medium: Media::TextMessagesBundle.create!(
#                                folder: sms,
#                                name: 'Semaine 2',
#                                body1: 'Semaine 2, message 1 !',
#                                image1: goods[0],
#                                body2: 'Semaine 2, message 2 !',
#                                image2: goods[1],
#                                body3: 'Semaine 2, message 3 !',
#                                image3: goods[2]
#                              ))
# puts ' ✓'

# print "\t\tSemaine 3"
# week_three = FactoryBot.create(:support_module_week,
#                                position: 3,
#                                medium: Media::TextMessagesBundle.create!(
#                                  folder: sms,
#                                  name: 'Semaine 3',
#                                  body1: 'Semaine 3, message 1 !',
#                                  image1: evils[0],
#                                  body2: 'Semaine 3, message 2 !',
#                                  image2: evils[1],
#                                  body3: 'Semaine 3, message 3 !',
#                                  image3: evils[2]
#                                ))
# puts ' ✓'

# Group
groups = [nil]
print "\tGroup"

5.times do
  groups << FactoryBot.create(:group)
end

puts ' ✓'

Child
if Rails.env.development?
  postal_code = Parent::ALL_POSTAL_CODE

  print "\t20 Children"

  20.times do
    parent1 = FactoryBot.create(:parent, postal_code: postal_code.sample, phone_number: '0755802002')
    parent2 = FactoryBot.create(:parent, postal_code: postal_code.sample, phone_number: '0667945009')
    rand(1..4).times do
      group = groups[rand(0..5)]
      child = FactoryBot.create(
        :child,
        parent1: parent1,
        should_contact_parent1: true,
        parent2: parent2,
        should_contact_parent2: true
      )
      child.group = group
      child.update(group_status: 'active') if child.group.present?
    end
  end
  puts ' ✓'
end

# Support Module
print "\tSupport Modules"

FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'language_module_zero',
                                   age_ranges: %w[four_to_nine], name: 'Test module 0 (4 - 9)')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language_module_zero', age_ranges: %w[ten_to_fifteen],
                                   name: 'Test module 0 (10 - 15)')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language_module_zero', age_ranges: %w[sixteen_to_twenty_three], name: 'Test module 0 (16 - 23)')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language_module_zero',
                                   age_ranges: %w[more_than_twenty_four], name: 'Test module 0 (24 +)')

FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'reading',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Garder l'intérêt de mon enfant avec les livres 📚")
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'reading', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: "Garder l'intérêt de mon enfant avec les livres 📚")
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'reading', age_ranges: %w[five_to_eleven], name: "Garder l'intérêt de mon enfant avec les livres 📚")
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Intéresser mon enfant aux livres 📚')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading', age_ranges: %w[eighteen_to_twenty_three], name: 'Intéresser mon enfant aux livres 📚')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading', age_ranges: %w[twelve_to_seventeen], name: 'Intéresser mon enfant aux livres 📚')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading', age_ranges: %w[less_than_five five_to_eleven], name: 'Intéresser mon enfant aux livres 📚')

FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'bilingualism',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Parler plusieurs langues à la maison 🏠')
FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'bilingualism', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: 'Parler plusieurs langues à la maison 🏠')
FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'bilingualism', age_ranges: %w[five_to_eleven], name: 'Parler plusieurs langues à la maison 🏠')

FactoryBot.create(:support_module, level: 3, for_bilingual: false, theme: 'language',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Parler encore plus avec mon enfant')
FactoryBot.create(:support_module, level: 3, for_bilingual: false, theme: 'language', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: 'Parler encore plus avec mon bébé')
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'language', age_ranges: %w[five_to_eleven twelve_to_seventeen], name: 'Parler plus avec mon bébé')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language', age_ranges: %w[five_to_eleven], name: 'Parler avec mon bébé 👶')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language', age_ranges: %w[less_than_five], name: 'Conversation spécial - de 4 mois')

FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'anger',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Parler pour mieux gérer les colères')

FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'ride', age_ranges: %w[twelve_to_seventeen],
                                   name: 'Découvrir le monde avec mon enfant pendant les sorties 🌳')

FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'games', age_ranges: %w[five_to_eleven], name: 'Des idées pour jouer avec mon bébé 🧩')

FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'screen',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Mieux gérer les écrans avec mon enfant 🖥')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'screen', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: 'Occuper mon enfant (sans les écrans) 🧩')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'screen', age_ranges: %w[five_to_eleven], name: 'Occuper mon enfant (sans les écrans) 🧩')

FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'songs',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Chanter souvent avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'songs', age_ranges: %w[twelve_to_seventeen], name: 'Chanter souvent avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'songs', age_ranges: %w[five_to_eleven], name: 'Chanter plus avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'songs',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Chanter avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'songs', age_ranges: %w[twelve_to_seventeen], name: 'Chanter avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'songs', age_ranges: %w[five_to_eleven], name: 'Chanter avec mon bébé 🎶')
puts ' ✓'
