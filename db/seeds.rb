puts '--- SEEDING DATABASE ---'

# AdminUser

puts "\tAdminUser"

print "\t\tadmin@example.com"
AdminUser.create!(user_role: 'super_admin', name: 'Admin', email: 'admin@example.com', password: 'Sido#1995', password_confirmation: 'Sido#1995') if Rails.env.development?
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
#     content_type: 'image/jpeg'
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
#     content_type: 'image/jpeg'
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

# 5.times do
#   groups << FactoryBot.create(:group, expected_children_number: 0)
# end

puts ' ✓'

# Child
if Rails.env.development?
  # postal_code = Parent::ALL_POSTAL_CODE

  print "\t Test des doublons"

    first_parent = FactoryBot.create(:parent, phone_number: '0755800000')
    second_parent = FactoryBot.create(:parent, phone_number: '0755800001')
    duplicated_parent = FactoryBot.create(:parent, phone_number: '0755800000')
    child_with_parent2 = FactoryBot.create(:child, first_name: 'Andréa', last_name: 'Manon', parent1: first_parent, parent2: second_parent)
    child_without_parent2 = FactoryBot.create(:child, first_name: 'andréA ', last_name: ' MaNon', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
    group = FactoryBot.create(:group, expected_children_number: 0)
    # group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
    child_with_parent2.update(group: group, group_status: 'active')
    child_without_parent2.update(group: group, group_status: 'active')

    first_parent = FactoryBot.create(:parent, phone_number: '0755800002')
    second_parent = FactoryBot.create(:parent, phone_number: '0755800003')
    duplicated_parent = FactoryBot.create(:parent, phone_number: '0755800002')
    child_with_parent2 = FactoryBot.create(:child, first_name: 'Hélène', last_name: 'Manitou', parent1: first_parent, parent2: second_parent)
    child_without_parent2 = FactoryBot.create(:child, first_name: 'HélènE ', last_name: ' MaNiToU', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
    group1 = FactoryBot.create(:group, expected_children_number: 0)
    group2 = FactoryBot.create(:group, expected_children_number: 0)
    # group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
    child_with_parent2.update(group: group1, group_status: 'active')
    child_without_parent2.update(group: group2, group_status: 'active')

    first_parent = FactoryBot.create(:parent, phone_number: '0755800004')
    second_parent = FactoryBot.create(:parent, phone_number: '0755800005')
    duplicated_parent = FactoryBot.create(:parent, phone_number: '0755800004')
    child_with_parent2 = FactoryBot.create(:child, first_name: 'Ana', last_name: 'Ninan', parent1: first_parent, parent2: second_parent)
    child_without_parent2 = FactoryBot.create(:child, first_name: 'AnA ', last_name: ' NinAn', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
    group = FactoryBot.create(:group, expected_children_number: 0)
    group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
    child_with_parent2.update(group: group, group_status: 'active')

    first_parent = FactoryBot.create(:parent, phone_number: '0755800006')
    second_parent = FactoryBot.create(:parent, phone_number: '0755800007')
    duplicated_parent = FactoryBot.create(:parent, phone_number: '0755800006')
    child_with_parent2 = FactoryBot.create(:child, first_name: 'Anasthasie', last_name: 'Ninanto', parent1: first_parent, parent2: second_parent)
    child_without_parent2 = FactoryBot.create(:child, first_name: 'AnAsThAsie ', last_name: ' NinAnTo', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
    group = FactoryBot.create(:group, expected_children_number: 0)
    group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
    child_without_parent2.update(group: group, group_status: 'active')

    first_parent = FactoryBot.create(:parent, phone_number: '0755800008')
    second_parent = FactoryBot.create(:parent, phone_number: '0755800009')
    duplicated_parent1 = FactoryBot.create(:parent, phone_number: '0755800008')
    duplicated_parent2 = FactoryBot.create(:parent, phone_number: '0755800009')
    child1 = FactoryBot.create(:child, first_name: 'asie', last_name: 'anto', parent1: first_parent, parent2: second_parent)
    child2 = FactoryBot.create(:child, first_name: 'Asie ', last_name: ' AnTo', birthdate: child1.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2)
    group = FactoryBot.create(:group, expected_children_number: 0)
    group2 = FactoryBot.create(:group, expected_children_number: 0)
    # group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
    child1.update(group: group, group_status: 'active')
    child2.update(group: group2, group_status: 'active')

    first_parent = FactoryBot.create(:parent, phone_number: '0755800018')
    second_parent = FactoryBot.create(:parent, phone_number: '0755800019')
    duplicated_parent1 = FactoryBot.create(:parent, phone_number: '0755800018')
    duplicated_parent2 = FactoryBot.create(:parent, phone_number: '0755800019')
    child1 = FactoryBot.create(:child, first_name: 'asTie', last_name: 'Ranto', parent1: first_parent, parent2: second_parent)
    child2 = FactoryBot.create(:child, first_name: 'Astie ', last_name: ' rAnTo', birthdate: child1.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2)
    group = FactoryBot.create(:group, expected_children_number: 0)
    group2 = FactoryBot.create(:group, expected_children_number: 0)
    group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
    child1.update(group: group, group_status: 'active')
    child2.update(group: group2, group_status: 'active')

    first_parent1 = FactoryBot.create(:parent, phone_number: '0755800010')
    first_parent2 = FactoryBot.create(:parent, phone_number: '0755800011')
    duplicated_first_parent1 = FactoryBot.create(:parent, phone_number: '0755800010')
    duplicated_first_parent2 = FactoryBot.create(:parent, phone_number: '0755800011')
    first_child = FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent1, parent2: first_parent2)
    duplicated_first_child = FactoryBot.create(:child, first_name: 'duplicate Prenom ', last_name: 'duplicate Nom', parent1: duplicated_first_parent1, parent2: duplicated_first_parent2)

  # 20.times do
  #   parent1 = FactoryBot.create(:parent, postal_code: postal_code.sample, phone_number: '0755802002')
  #   parent2 = FactoryBot.create(:parent, postal_code: postal_code.sample, phone_number: '0667945009')
  #   rand(1..4).times do
  #     group = groups[rand(0..5)]
  #     child = FactoryBot.create(
  #       :child,
  #       parent1: parent1,
  #       should_contact_parent1: true,
  #       parent2: parent2,
  #       should_contact_parent2: true
  #     )
  #     child.group = group
  #     child.update(group_status: 'active') if child.group.present?
  #   end
  # end
  puts ' ✓'
end

# Support Module
print "\tSupport Modules"

FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'language_module_zero',
                                   age_ranges: %w[four_to_ten], name: 'Test module 0 (4 - 10)')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language_module_zero', age_ranges: %w[eleven_to_sixteen],
                                   name: 'Test module 0 (10 - 15)')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language_module_zero', age_ranges: %w[seventeen_to_twenty_two], name: 'Test module 0 (16 - 23)')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language_module_zero',
                                   age_ranges: %w[twenty_three_and_more], name: 'Test module 0 (24 +)')

FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'reading',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Garder l'intérêt de mon enfant avec les livres 📚")
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'reading', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: "Garder l'intérêt de mon enfant avec les livres 📚")
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'reading', age_ranges: %w[four_to_eleven], name: "Garder l'intérêt de mon enfant avec les livres 📚")
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Intéresser mon enfant aux livres 📚')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading', age_ranges: %w[eighteen_to_twenty_three], name: 'Intéresser mon enfant aux livres 📚')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading', age_ranges: %w[twelve_to_seventeen], name: 'Intéresser mon enfant aux livres 📚')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'reading', age_ranges: %w[four_to_eleven], name: 'Intéresser mon enfant aux livres 📚')

FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'bilingualism',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Parler plusieurs langues à la maison 🏠')
FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'bilingualism', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: 'Parler plusieurs langues à la maison 🏠')
FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: 'bilingualism', age_ranges: %w[four_to_eleven], name: 'Parler plusieurs langues à la maison 🏠')

FactoryBot.create(:support_module, level: 3, for_bilingual: false, theme: 'language',
                                   age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Parler encore plus avec mon enfant')
FactoryBot.create(:support_module, level: 3, for_bilingual: false, theme: 'language', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: 'Parler encore plus avec mon bébé')
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'language', age_ranges: %w[four_to_eleven twelve_to_seventeen], name: 'Parler plus avec mon bébé')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'language', age_ranges: %w[four_to_eleven], name: 'Parler avec mon bébé 👶')

FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'anger',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Parler pour mieux gérer les colères')

FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'ride', age_ranges: %w[twelve_to_seventeen],
                                   name: 'Découvrir le monde avec mon enfant pendant les sorties 🌳')

FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'games', age_ranges: %w[four_to_eleven], name: 'Des idées pour jouer avec mon bébé 🧩')

FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'screen',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Mieux gérer les écrans avec mon enfant 🖥')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'screen', age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                   name: 'Occuper mon enfant (sans les écrans) 🧩')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'screen', age_ranges: %w[four_to_eleven], name: 'Occuper mon enfant (sans les écrans) 🧩')

FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'songs',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Chanter souvent avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'songs', age_ranges: %w[twelve_to_seventeen], name: 'Chanter souvent avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: 'songs', age_ranges: %w[four_to_eleven], name: 'Chanter plus avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'songs',
                                   age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: 'Chanter avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'songs', age_ranges: %w[twelve_to_seventeen], name: 'Chanter avec mon bébé 🎶')
FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: 'songs', age_ranges: %w[four_to_eleven], name: 'Chanter avec mon bébé 🎶')
puts ' ✓'
