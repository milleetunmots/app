puts '--- SEEDING DATABASE ---'

# =============================================================================
# SUPPORT MODULES (tous environnements)
# =============================================================================
print "\tSupport Modules"

# Module 0 (tranches d'age specifiques)
sm_mod0_4_10 = SupportModule.create!(level: 1, for_bilingual: true, theme: 'language_module_zero',
                                     age_ranges: %w[four_to_ten], name: 'Test module 0 (4 - 10)')
sm_mod0_11_16 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'language_module_zero',
                                      age_ranges: %w[eleven_to_sixteen], name: 'Test module 0 (10 - 15)')
sm_mod0_17_22 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'language_module_zero',
                                      age_ranges: %w[seventeen_to_twenty_two], name: 'Test module 0 (16 - 23)')
sm_mod0_23p = SupportModule.create!(level: 1, for_bilingual: false, theme: 'language_module_zero',
                                    age_ranges: %w[twenty_three_and_more], name: 'Test module 0 (24 +)')

# Lecture
sm_lecture_2_grands = SupportModule.create!(level: 2, for_bilingual: false, theme: 'reading',
                                           age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                           name: "Garder l'interet de mon enfant avec les livres (grands)")
sm_lecture_2_moyens = SupportModule.create!(level: 2, for_bilingual: false, theme: 'reading',
                                           age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                           name: "Garder l'interet de mon enfant avec les livres (moyens)")
sm_lecture_2_petits = SupportModule.create!(level: 2, for_bilingual: false, theme: 'reading',
                                           age_ranges: %w[four_to_eleven],
                                           name: "Garder l'interet de mon enfant avec les livres (petits)")
sm_lecture_1_grands = SupportModule.create!(level: 1, for_bilingual: false, theme: 'reading',
                                           age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                           name: 'Interesser mon enfant aux livres (grands)')
sm_lecture_1_18_23 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'reading',
                                          age_ranges: %w[eighteen_to_twenty_three],
                                          name: 'Interesser mon enfant aux livres (18-23)')
sm_lecture_1_12_17 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'reading',
                                          age_ranges: %w[twelve_to_seventeen],
                                          name: 'Interesser mon enfant aux livres (12-17)')
sm_lecture_1_4_11 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'reading',
                                         age_ranges: %w[four_to_eleven],
                                         name: 'Interesser mon enfant aux livres (4-11)')

# Bilinguisme
sm_bilinguisme_grands = SupportModule.create!(level: 1, for_bilingual: true, theme: 'bilingualism',
                                             age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                             name: 'Parler plusieurs langues a la maison (grands)')
sm_bilinguisme_moyens = SupportModule.create!(level: 1, for_bilingual: true, theme: 'bilingualism',
                                             age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                             name: 'Parler plusieurs langues a la maison (moyens)')
sm_bilinguisme_petits = SupportModule.create!(level: 1, for_bilingual: true, theme: 'bilingualism',
                                             age_ranges: %w[four_to_eleven],
                                             name: 'Parler plusieurs langues a la maison (petits)')

# Langage
sm_langage_3 = SupportModule.create!(level: 3, for_bilingual: false, theme: 'language',
                                     age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                     name: 'Parler encore plus avec mon enfant')
sm_langage_3_moyens = SupportModule.create!(level: 3, for_bilingual: false, theme: 'language',
                                           age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                           name: 'Parler encore plus avec mon bebe')
sm_langage_2 = SupportModule.create!(level: 2, for_bilingual: false, theme: 'language',
                                     age_ranges: %w[four_to_eleven twelve_to_seventeen],
                                     name: 'Parler plus avec mon bebe')
sm_langage_1 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'language',
                                     age_ranges: %w[four_to_eleven],
                                     name: 'Parler avec mon bebe')

# Colere
sm_colere = SupportModule.create!(level: 1, for_bilingual: false, theme: 'anger',
                                  age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                  name: 'Parler pour mieux gerer les coleres')

# Sorties
sm_sorties = SupportModule.create!(level: 1, for_bilingual: false, theme: 'ride',
                                   age_ranges: %w[twelve_to_seventeen],
                                   name: 'Decouvrir le monde avec mon enfant pendant les sorties')

# Jeux
sm_jeux = SupportModule.create!(level: 1, for_bilingual: false, theme: 'games',
                                age_ranges: %w[four_to_eleven],
                                name: 'Des idees pour jouer avec mon bebe')

# Ecrans
sm_ecrans_2 = SupportModule.create!(level: 2, for_bilingual: false, theme: 'screen',
                                    age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                    name: 'Mieux gerer les ecrans avec mon enfant')
sm_ecrans_1_moyens = SupportModule.create!(level: 1, for_bilingual: false, theme: 'screen',
                                          age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three],
                                          name: 'Occuper mon enfant sans les ecrans (moyens)')
sm_ecrans_1_petits = SupportModule.create!(level: 1, for_bilingual: false, theme: 'screen',
                                          age_ranges: %w[four_to_eleven],
                                          name: 'Occuper mon enfant sans les ecrans (petits)')

# Comptines
sm_comptines_2_grands = SupportModule.create!(level: 2, for_bilingual: false, theme: 'songs',
                                             age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                             name: 'Chanter souvent avec mon bebe (grands)')
sm_comptines_2_12_17 = SupportModule.create!(level: 2, for_bilingual: false, theme: 'songs',
                                            age_ranges: %w[twelve_to_seventeen],
                                            name: 'Chanter souvent avec mon bebe (12-17)')
sm_comptines_2_4_11 = SupportModule.create!(level: 2, for_bilingual: false, theme: 'songs',
                                           age_ranges: %w[four_to_eleven],
                                           name: 'Chanter plus avec mon bebe (4-11)')
sm_comptines_1_grands = SupportModule.create!(level: 1, for_bilingual: false, theme: 'songs',
                                             age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four],
                                             name: 'Chanter avec mon bebe (grands)')
sm_comptines_1_12_17 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'songs',
                                            age_ranges: %w[twelve_to_seventeen],
                                            name: 'Chanter avec mon bebe (12-17)')
sm_comptines_1_4_11 = SupportModule.create!(level: 1, for_bilingual: false, theme: 'songs',
                                           age_ranges: %w[four_to_eleven],
                                           name: 'Chanter avec mon bebe (4-11)')
puts ' ✓'

  # Helper : creer un parent en bypassant la validation phone (0800000000 n'est pas mobile)
def create_seed_parent!(attrs)
  parent = Parent.new(attrs)
  parent.save!(validate: false)
  parent
end

  # ===========================================================================
  # 1. ADMIN USERS (5 roles)
  # ===========================================================================
puts "\tAdmin Users"

admin = AdminUser.create!(
  user_role: 'super_admin', name: 'Admin Super', email: 'admin@example.com',
  password: 'Sido#1995', password_confirmation: 'Sido#1995',
  aircall_phone_number: '0800000000', aircall_number_id: 1_000_000_001,
  can_send_automatic_sms: true, can_treat_task: true, can_export_data: true
)
puts "\t\t#{admin.email} (super_admin) ✓"

contributor = AdminUser.create!(
  user_role: 'contributor', name: 'Marie Contributrice', email: 'contributor@example.com',
  password: 'Sido#1995', password_confirmation: 'Sido#1995',
  aircall_phone_number: '0800000000', aircall_number_id: 1_000_000_002,
  can_send_automatic_sms: true, can_export_data: true
)
puts "\t\t#{contributor.email} (contributor) ✓"

reader = AdminUser.create!(
  user_role: 'reader', name: 'Jean Lecteur', email: 'reader@example.com',
  password: 'Sido#1995', password_confirmation: 'Sido#1995',
  aircall_phone_number: '0800000000', aircall_number_id: 1_000_000_003
)
puts "\t\t#{reader.email} (reader) ✓"

caller_user = AdminUser.create!(
  user_role: 'caller', name: 'Sophie Appelante', email: 'caller@example.com',
  password: 'Sido#1995', password_confirmation: 'Sido#1995',
  aircall_phone_number: '0800000000', aircall_number_id: 1_000_000_004,
  can_treat_task: true
)
puts "\t\t#{caller_user.email} (caller) ✓"

animator_user = AdminUser.create!(
  user_role: 'animator', name: 'Claire Animatrice', email: 'animator@example.com',
  password: 'Sido#1995', password_confirmation: 'Sido#1995',
  aircall_phone_number: '0800000000', aircall_number_id: 1_000_000_005
)
puts "\t\t#{animator_user.email} (animator) ✓"

  # ===========================================================================
  # 2. TAGS
  # ===========================================================================
puts "\tTags"

Tag.create!(name: 'desengagement empeche', color: '#FF6B6B', is_visible_by_callers_and_animators: true)
Tag.create!(name: 'eval', color: '#4ECDC4', is_visible_by_callers_and_animators: true)
Tag.create!(name: 'bilingue', color: '#45B7D1', is_visible_by_callers_and_animators: true)
Tag.create!(name: 'whatsapp', is_visible_by_callers_and_animators: false)
Tag.create!(name: '2eme cohorte', color: '#96CEB4', is_visible_by_callers_and_animators: true)
Tag.create!(name: 'hors cible', color: '#FFEAA7', is_visible_by_callers_and_animators: false)
puts "\t\t6 tags ✓"

  # ===========================================================================
  # 3. BOOKS
  # ===========================================================================
puts "\tBooks"

book1 = Book.create!(ean: '9782070612758', title: 'Le Petit Prince')
book2 = Book.create!(ean: '9782070624539', title: 'Les Trois Brigands')
book3 = Book.create!(ean: '9782211012805', title: 'Bebes Chouettes')
book4 = Book.create!(ean: '9782070654840', title: 'La Chenille Qui Fait Des Trous')
book5 = Book.create!(ean: '9782070619825', title: 'Petit Ours Brun')
puts "\t\t5 books ✓"

  # Lier des livres aux modules
sm_lecture_1_4_11.update!(book: book1)
sm_lecture_1_12_17.update!(book: book2)
sm_lecture_1_18_23.update!(book: book3)
sm_comptines_1_4_11.update!(book: book4)
sm_jeux.update!(book: book5)

  # ===========================================================================
  # 4. MEDIA (Dossiers, Videos, Bundles SMS)
  # ===========================================================================
puts "\tMedia"

sms_folder = MediaFolder.create!(name: 'SMS')
videos_folder = MediaFolder.create!(name: 'Videos')

video1 = Media::Video.create!(name: 'Lire avec bebe', url: 'https://example.com/video1', folder: videos_folder, airtable_id: 'rec123456789')
video2 = Media::Video.create!(name: 'Chanter ensemble', url: 'https://example.com/video2', folder: videos_folder, airtable_id: 'rec123456779')
video3 = Media::Video.create!(name: 'Jouer et apprendre', url: 'https://example.com/video3', folder: videos_folder, airtable_id: 'rec12056789')

bundle1 = Media::TextMessagesBundle.create!(
  name: 'Semaine 1 - Lecture', folder: sms_folder,
  body1: 'Bonjour ! Cette semaine, lisez un livre avec {PRENOM_ENFANT}. {URL}',
  body2: 'Astuce : montrez les images du livre a votre enfant en lisant.',
  body3: '{PRENOM_ACCOMPAGNANTE} vous souhaite une bonne lecture !',
  link1: video1
)
bundle2 = Media::TextMessagesBundle.create!(
  name: 'Semaine 2 - Chansons', folder: sms_folder,
  body1: 'Bonjour ! Chantez avec {PRENOM_ENFANT} cette semaine. {URL}',
  body2: 'Les comptines aident au developpement du langage.',
  body3: 'Bonne semaine de la part de {PRENOM_ACCOMPAGNANTE} !',
  link1: video2
)
bundle3 = Media::TextMessagesBundle.create!(
  name: 'Semaine 3 - Jeux', folder: sms_folder,
  body1: 'Jouez avec {PRENOM_ENFANT} cette semaine ! {URL}',
  body2: 'Les jeux simples stimulent le developpement.',
  body3: 'A la semaine prochaine !',
  link1: video3
)
bundle_additional = Media::TextMessagesBundle.create!(
  name: 'Semaine 1 - Complement', folder: sms_folder,
  body1: 'Petit rappel : avez-vous lu avec {PRENOM_ENFANT} cette semaine ?'
)
puts "\t\t2 dossiers, 3 videos, 4 bundles ✓"

  # ===========================================================================
  # 5. SUPPORT MODULE WEEKS (lie modules aux bundles SMS)
  # ===========================================================================
puts "\tSupport Module Weeks"

smw1 = SupportModuleWeek.create!(support_module: sm_lecture_1_4_11, medium: bundle1, position: 1)
smw1.update!(additional_medium: bundle_additional)
SupportModuleWeek.create!(support_module: sm_lecture_1_4_11, medium: bundle2, position: 2)
SupportModuleWeek.create!(support_module: sm_lecture_1_4_11, medium: bundle3, position: 3)

SupportModuleWeek.create!(support_module: sm_comptines_1_4_11, medium: bundle2, position: 1)
SupportModuleWeek.create!(support_module: sm_comptines_1_4_11, medium: bundle3, position: 2)

SupportModuleWeek.create!(support_module: sm_langage_1, medium: bundle1, position: 1)
SupportModuleWeek.create!(support_module: sm_langage_1, medium: bundle3, position: 2)
puts "\t\t7 support module weeks ✓"

  # ===========================================================================
  # 6. SOURCES
  # ===========================================================================
puts "\tSources"

source_caf = Source.create!(name: 'CAF 93', channel: 'caf', department: 93)
source_pmi = Source.create!(name: 'PMI Bondy', channel: 'pmi', department: 93)
source_bao = Source.create!(name: 'BAO Orleans', channel: 'bao', utm: 'bao_orleans')
source_partner = Source.create!(name: 'Partenaire Paris 20', channel: 'local_partner', utm: 'partenaire_paris20')
source_other = Source.create!(name: 'Autre canal', channel: 'other', utm: 'autre_canal')
puts "\t\t5 sources ✓"

  # ===========================================================================
  # 7. GROUPS (actif, termine, futur, sans appels, exclu analytics)
  # ===========================================================================
puts "\tGroups"

past_monday_4w = (Time.zone.today.prev_occurring(:monday) - 4.weeks).next_occurring(:monday)
past_monday_9w = (Time.zone.today.prev_occurring(:monday) - 9.weeks).next_occurring(:monday)
past_monday_13w = (Time.zone.today.prev_occurring(:monday) - 13.weeks).next_occurring(:monday)
past_monday_18w = (Time.zone.today.prev_occurring(:monday) - 18.weeks).next_occurring(:monday)
past_monday_8m = (Time.zone.today.prev_occurring(:monday) - 8.months).next_occurring(:monday)
future_monday = (Time.zone.today.next_occurring(:monday) + 2.weeks).next_occurring(:monday)

first_active_group = Group.create!(
  name: 'Cohorte Active Paris', started_at: past_monday_4w,
  expected_children_number: 30, support_modules_count: 5, type_of_support: 'with_calls'
)
second_active_group = Group.create!(
  name: 'Cohorte Active Paris', started_at: past_monday_9w,
  expected_children_number: 30, support_modules_count: 5, type_of_support: 'with_calls'
)
third_active_group = Group.create!(
  name: 'Cohorte Active Paris', started_at: past_monday_13w,
  expected_children_number: 30, support_modules_count: 5, type_of_support: 'with_calls'
)
fourth_active_group = Group.create!(
  name: 'Cohorte Active Paris', started_at: past_monday_18w,
  expected_children_number: 30, support_modules_count: 5, type_of_support: 'with_calls'
)

first_active_group.update_columns(support_module_programmed: 1)
second_active_group.update_columns(support_module_programmed: 2)
third_active_group.update_columns(support_module_programmed: 3)
fourth_active_group.update_columns(support_module_programmed: 4)

ended_group = Group.create!(
  name: 'Cohorte Terminee Bondy', started_at: past_monday_8m,
  expected_children_number: 20, support_modules_count: 4, type_of_support: 'with_calls'
)
ended_group.update_columns(ended_at: 2.weeks.ago.to_date)

future_group = Group.create!(
  name: 'Cohorte Future Orleans', started_at: future_monday,
  expected_children_number: 25, support_modules_count: 5, type_of_support: 'with_calls'
)

no_calls_group = Group.create!(
  name: 'Cohorte Sans Appels', started_at: past_monday_4w,
  expected_children_number: 15, support_modules_count: 3, type_of_support: 'without_calls'
)
no_calls_group.update_columns(support_module_programmed: 1)

excluded_group = Group.create!(
  name: 'Cohorte Exclue Analytics', started_at: past_monday_4w,
  expected_children_number: 10, support_modules_count: 2,
  type_of_support: 'with_calls', is_excluded_from_analytics: true
)
excluded_group.update_columns(support_module_programmed: 1)

active_groups = [first_active_group, second_active_group, third_active_group, fourth_active_group, excluded_group]

puts "\t\tGroups ✓"

  # ===========================================================================
  # 8. PARENTS (10 parents varies)
  # ===========================================================================
puts "\tParents"

base_attrs = {
  phone_number: '0800000000', terms_accepted_at: 1.month.ago,
  book_delivery_location: 'home'
}

  # Meres
mere1 = create_seed_parent!(base_attrs.merge(
  gender: 'f', first_name: 'Marie', last_name: 'Dupont',
  email: 'marie.dupont@example.com', preferred_channel: 'sms',
  address: '10 Rue de la Paix', postal_code: '75020', city_name: 'Paris',
  letterbox_name: 'Famille Dupont'
))
mere2 = create_seed_parent!(base_attrs.merge(
  gender: 'f', first_name: 'Fatima', last_name: 'Benali',
  email: 'fatima.benali@example.com', preferred_channel: 'whatsapp',
  address: '5 Avenue Jean Jaures', postal_code: '93140', city_name: 'Bondy',
  letterbox_name: 'Famille Benali'
))
mere3 = create_seed_parent!(base_attrs.merge(
  gender: 'f', first_name: 'Sophie', last_name: 'Martin',
  email: 'sophie.martin@example.com', is_ambassador: true,
  address: '20 Rue Jeanne dArc', postal_code: '45000', city_name: 'Orleans',
  letterbox_name: 'Famille Martin'
))
mere4 = create_seed_parent!(base_attrs.merge(
  gender: 'f', first_name: 'Amina', last_name: 'Diallo',
  is_excluded_from_workshop: true,
  address: '15 Rue Victor Hugo', postal_code: '93600', city_name: 'Aulnay-sous-Bois',
  letterbox_name: 'Famille Diallo'
))
mere5 = create_seed_parent!(base_attrs.merge(
  gender: 'f', first_name: 'Lea', last_name: 'Petit',
  address: '8 Rue du Chateau', postal_code: '92390', city_name: 'Villeneuve-la-Garenne',
  letterbox_name: 'Famille Petit',
  book_delivery_location: 'pmi', book_delivery_organisation_name: 'PMI Centre Ville'
))
mere6 = create_seed_parent!(base_attrs.merge(
  gender: 'f', first_name: 'Nadia', last_name: 'Khelifi',
  address: '42 Rue des Pyrenees', postal_code: '75020', city_name: 'Paris',
  letterbox_name: 'Famille Khelifi'
))

  # Peres
pere1 = create_seed_parent!(base_attrs.merge(
  gender: 'm', first_name: 'Pierre', last_name: 'Dupont',
  address: '10 Rue de la Paix', postal_code: '75020', city_name: 'Paris',
  letterbox_name: 'Famille Dupont'
))
pere2 = create_seed_parent!(base_attrs.merge(
  gender: 'm', first_name: 'Ahmed', last_name: 'Benali',
  address: '5 Avenue Jean Jaures', postal_code: '93140', city_name: 'Bondy',
  letterbox_name: 'Famille Benali'
))
pere3 = create_seed_parent!(base_attrs.merge(
  gender: 'm', first_name: 'Thomas', last_name: 'Martin',
  address: '20 Rue Jeanne dArc', postal_code: '45000', city_name: 'Orleans',
  letterbox_name: 'Famille Martin'
))
pere4 = create_seed_parent!(base_attrs.merge(
  gender: 'm', first_name: 'Mamadou', last_name: 'Diallo',
  address: '15 Rue Victor Hugo', postal_code: '93600', city_name: 'Aulnay-sous-Bois',
  letterbox_name: 'Famille Diallo'
))
puts "\t\t10 parents ✓"

  # ===========================================================================
  # 9. CHILDREN (ages, statuts et groupes varies)
  # ===========================================================================
puts "\tChildren"

  # --- Groupe actif : enfants actifs avec ages varies ---
  # 6 mois (tranche 4-11)
enfant1 = Child.new(
  parent1: mere1, parent2: pere1, first_name: 'Lucas', last_name: 'Dupont',
  gender: 'm', birthdate: 6.months.ago.to_date,
  should_contact_parent1: true, should_contact_parent2: true
)
enfant1.save!(validate: false)
enfant1.update_columns(group_id: active_groups.sample.id, group_status: 'active', available_for_workshops: true)

  # 14 mois (tranche 12-17)
enfant2 = Child.new(
  parent1: mere2, parent2: pere2, first_name: 'Yasmine', last_name: 'Benali',
  gender: 'f', birthdate: 14.months.ago.to_date,
  should_contact_parent1: true, should_contact_parent2: true
)
enfant2.save!(validate: false)
enfant2.update_columns(group_id: active_groups.sample.id, group_status: 'active', available_for_workshops: true)

  # 20 mois (tranche 18-23)
enfant3 = Child.new(
  parent1: mere3, parent2: pere3, first_name: 'Emma', last_name: 'Martin',
  gender: 'f', birthdate: 20.months.ago.to_date,
  should_contact_parent1: true, should_contact_parent2: false
)
enfant3.save!(validate: false)
enfant3.update_columns(group_id: active_groups.sample.id, group_status: 'active', available_for_workshops: true)

  # 26 mois (tranche 24-29)
enfant4 = Child.new(
  parent1: mere4, parent2: pere4, first_name: 'Ibrahim', last_name: 'Diallo',
  gender: 'm', birthdate: 26.months.ago.to_date,
  should_contact_parent1: true, should_contact_parent2: true
)
enfant4.save!(validate: false)
enfant4.update_columns(group_id: active_groups.sample.id, group_status: 'active')

  # --- Groupe actif : statuts non-actifs ---
  # En pause
enfant5 = Child.new(
  parent1: mere5, first_name: 'Chloe', last_name: 'Petit',
  gender: 'f', birthdate: 10.months.ago.to_date, should_contact_parent1: true
)
enfant5.save!(validate: false)
enfant5.update_columns(group_id: active_groups.sample.id, group_status: 'paused')

  # Arrete
enfant6 = Child.new(
  parent1: mere6, first_name: 'Adam', last_name: 'Khelifi',
  gender: 'm', birthdate: 16.months.ago.to_date, should_contact_parent1: true
)
enfant6.save!(validate: false)
enfant6.update_columns(group_id: active_groups.sample.id, group_status: 'stopped')

  # Desengage (fratrie avec enfant1 via mere1)
enfant7 = Child.new(
  parent1: mere1, first_name: 'Leo', last_name: 'Dupont',
  gender: 'm', birthdate: 12.months.ago.to_date, should_contact_parent1: true
)
enfant7.save!(validate: false)
enfant7.update_columns(group_id: active_groups.sample.id, group_status: 'disengaged')

  # --- En attente (pas de groupe) ---
enfant8 = Child.new(
  parent1: mere2, first_name: 'Sofia', last_name: 'Benali',
  gender: 'f', birthdate: 4.months.ago.to_date, should_contact_parent1: true
)
enfant8.save!(validate: false)
  # group_status = 'waiting', group_id = nil (defaut)

  # --- Non accompagne ---
enfant9 = Child.new(
  parent1: mere3, first_name: 'Hugo', last_name: 'Martin',
  gender: 'm', birthdate: 8.months.ago.to_date, should_contact_parent1: true
)
enfant9.save!(validate: false)
enfant9.update_columns(group_status: 'not_supported')

  # --- Groupe sans appels ---
enfant10 = Child.new(
  parent1: mere4, first_name: 'Aya', last_name: 'Diallo',
  gender: 'f', birthdate: 15.months.ago.to_date, should_contact_parent1: true
)
enfant10.save!(validate: false)
enfant10.update_columns(group_id: no_calls_group.id, group_status: 'active')

  # --- Groupe termine ---
enfant11 = Child.new(
  parent1: mere5, first_name: 'Raphael', last_name: 'Petit',
  gender: 'm', birthdate: 28.months.ago.to_date, should_contact_parent1: true
)
enfant11.save!(validate: false)
enfant11.update_columns(group_id: ended_group.id, group_status: 'active')

  # --- Groupe futur ---
enfant12 = Child.new(
  parent1: mere6, first_name: 'Ines', last_name: 'Khelifi',
  gender: 'f', birthdate: 5.months.ago.to_date, should_contact_parent1: true
)
enfant12.save!(validate: false)
enfant12.update_columns(group_id: future_group.id, group_status: 'active')

  # --- Groupe exclu analytics ---
enfant13 = Child.new(
  parent1: mere1, first_name: 'Jules', last_name: 'Dupont',
  gender: 'm', birthdate: 18.months.ago.to_date, should_contact_parent1: true
)
enfant13.save!(validate: false)
enfant13.update_columns(group_id: excluded_group.id, group_status: 'active')

puts "\t\t13 children ✓"

  # ===========================================================================
  # 10. CHILD SUPPORTS (attribution supporters, donnees appels)
  # ===========================================================================
puts "\tChild Supports"

  # Attribution des supporters
[enfant1, enfant2, enfant3, enfant4, enfant7].each do |child|
  child.child_support&.update_columns(supporter_id: caller_user.id)
end
[enfant5, enfant6, enfant10].each do |child|
  child.child_support&.update_columns(supporter_id: animator_user.id)
end

  # Donnees d'appels detaillees
if (cs = enfant1.child_support)
  cs.update_columns(
    is_bilingual: '1_no',
    call0_status: '1_ok', call0_duration: 15,
    call0_goals: 'Lire 10 min par jour', call0_goals_sms: 'Objectif : lire 10 min par jour avec Lucas !',
    call0_reading_frequency: '2_weekly', call0_parent_progress: '2_medium',
    call0_sendings_benefits: '3_remind', call0_language_awareness: '2_awareness',
    books_quantity: '2_three_or_less', to_call: false,
    calendly_booking_url: 'https://calendly.com/example/appel-suivi'
  )
end

if (cs = enfant2.child_support)
  cs.update_columns(
    is_bilingual: '0_yes',
    call0_status: '1_ok', call0_duration: 20,
    call0_goals: 'Chanter en arabe et en francais',
    call0_goals_sms: 'Objectif : chanter une comptine par jour avec Yasmine !',
    call0_reading_frequency: '3_frequently', call0_parent_progress: '3_high',
    call1_status: '1_ok', call1_duration: 18,
    call1_goals: 'Raconter des histoires bilingues',
    call1_goals_sms: 'Objectif : raconter une histoire bilingue cette semaine !',
    call1_family_progress: '1_yes', call1_previous_goals_follow_up: '1_succeed',
    books_quantity: '3_between_four_and_ten', to_call: false
  )
end

if (cs = enfant3.child_support)
  cs.update_columns(
    is_bilingual: '2_no_information',
    call0_status: '2_ko', call0_duration: 0,
    to_call: true,
    important_information: 'Parent difficile a joindre',
    has_important_information_parental_consent: true
  )
end

if (cs = enfant4.child_support)
  cs.update_columns(
    is_bilingual: '0_yes',
    call0_status: '1_ok', call0_duration: 25,
    call1_status: '1_ok', call1_duration: 20,
    call2_status: '5_unfinished', call2_duration: 5,
    books_quantity: '4_more_than_ten', to_call: true
  )
end

if (cs = enfant5.child_support)
  cs.update_columns(
    call0_status: '1_ok', call0_duration: 12,
    call1_status: '3_unassigned_number'
  )
end

if (cs = enfant6.child_support)
  cs.update_columns(
    stop_support_date: 1.week.ago, stop_support_details: 'Famille demenagee',
    stop_support_reason: 'Demenagement'
  )
end

  # Sans supporter (pour tester la distribution auto)
enfant10.child_support&.update_columns(supporter_id: nil)

puts "\t\tChild supports mis a jour ✓"

  # ===========================================================================
  # 11. CHILDREN SUPPORT MODULES
  # ===========================================================================
puts "\tChildren Support Modules"

  # Module choisi, programme
csm1 = ChildrenSupportModule.new(
  child: enfant1, parent: mere1, support_module: sm_lecture_1_4_11,
  is_programmed: true, is_completed: false, module_index: 1,
  available_support_module_list: [sm_lecture_1_4_11.id.to_s, sm_jeux.id.to_s, sm_langage_1.id.to_s]
)
csm1.save!(validate: false)

  # Module choisi, pas encore programme
csm2 = ChildrenSupportModule.new(
  child: enfant2, parent: mere2, support_module: sm_comptines_1_12_17,
  is_programmed: false, is_completed: false, module_index: 1,
  available_support_module_list: [sm_comptines_1_12_17.id.to_s, sm_lecture_1_12_17.id.to_s, sm_sorties.id.to_s]
)
csm2.save!(validate: false)

  # Module complete
csm3 = ChildrenSupportModule.new(
  child: enfant3, parent: mere3, support_module: sm_lecture_1_18_23,
  is_programmed: true, is_completed: true, module_index: 1, book: book3,
  available_support_module_list: [sm_lecture_1_18_23.id.to_s, sm_colere.id.to_s]
)
csm3.save!(validate: false)

  # Livre non recu
csm4 = ChildrenSupportModule.new(
  child: enfant4, parent: mere4, support_module: sm_lecture_1_grands,
  is_programmed: true, is_completed: false, module_index: 1,
  book: book1, book_condition: 'not_received',
  available_support_module_list: [sm_lecture_1_grands.id.to_s, sm_bilinguisme_grands.id.to_s]
)
csm4.save!(validate: false)

  # Sans module choisi (a choisir)
csm5 = ChildrenSupportModule.new(
  child: enfant10, parent: mere4,
  is_programmed: false, is_completed: false, module_index: 1,
  available_support_module_list: [sm_lecture_1_12_17.id.to_s, sm_comptines_1_12_17.id.to_s]
)
csm5.save!(validate: false)

puts "\t\t5 children support modules ✓"

  # ===========================================================================
  # 12. CHILDREN SOURCES
  # ===========================================================================
puts "\tChildren Sources"

ChildrenSource.create!(child: enfant1, source: source_caf, details: 'Inscription CAF en ligne')
ChildrenSource.create!(child: enfant2, source: source_pmi, details: 'Orientation PMI Bondy')
ChildrenSource.create!(child: enfant3, source: source_bao, details: 'Bouche a oreille')
ChildrenSource.create!(child: enfant4, source: source_partner)
ChildrenSource.create!(child: enfant10, source: source_caf)
ChildrenSource.create!(child: enfant12, source: source_other, details: 'Recommandation voisine')
puts "\t\t6 children sources ✓"

  # ===========================================================================
  # 13. REDIRECTION TARGETS & URLS
  # ===========================================================================
puts "\tRedirection Targets & URLs"

rt1 = RedirectionTarget.create!(medium: video1)
rt2 = RedirectionTarget.create!(medium: video2)

[[mere1, enfant1], [mere2, enfant2], [mere3, enfant3], [mere4, enfant4]].each do |parent, child|
  RedirectionUrl.create!(redirection_target: rt1, parent: parent, child: child, security_code: SecureRandom.hex(4))
  RedirectionUrl.create!(redirection_target: rt2, parent: parent, child: child, security_code: SecureRandom.hex(4))
end

  # Ajouter des visites sur certaines URLs
RedirectionUrl.where(parent: mere1).each do |url|
  2.times { RedirectionUrlVisit.create!(redirection_url: url) }
  url.update_column(:redirection_url_visits_count, 2)
end
RedirectionUrl.where(parent: mere2).first&.tap do |url|
  RedirectionUrlVisit.create!(redirection_url: url)
  url.update_column(:redirection_url_visits_count, 1)
end

puts "\t\t2 targets, 8 URLs, 5 visits ✓"

  # ===========================================================================
  # 14. SURVEYS, QUESTIONS, ANSWERS
  # ===========================================================================
puts "\tSurveys"

survey = Survey.create!(name: 'Enquete satisfaction module 1')
q1 = Question.create!(survey: survey, name: 'Avez-vous lu avec votre enfant cette semaine ?', uid: 'q_lecture_hebdo', order: 1)
q2 = Question.create!(survey: survey, name: 'Combien de minutes par jour ?', uid: 'q_duree_lecture', order: 2, with_open_ended_response: true)
q3 = Question.create!(survey: survey, name: 'Recommanderiez-vous le programme ?', uid: 'q_recommandation', order: 3)

a1_yes = Answer.create!(question: q1, response: 'Oui')
a1_no = Answer.create!(question: q1, response: 'Non')
a2_5 = Answer.create!(question: q2, response: '5 minutes')
a2_10 = Answer.create!(question: q2, response: '10 minutes')
a2_15 = Answer.create!(question: q2, response: '15 minutes ou plus')
a3_yes = Answer.create!(question: q3, response: 'Oui, absolument')
a3_maybe = Answer.create!(question: q3, response: 'Peut-etre')
a3_no = Answer.create!(question: q3, response: 'Non')

ParentsAnswer.create!(parent: mere1, answer: a1_yes)
ParentsAnswer.create!(parent: mere1, answer: a2_10)
ParentsAnswer.create!(parent: mere1, answer: a3_yes)
ParentsAnswer.create!(parent: mere2, answer: a1_yes)
ParentsAnswer.create!(parent: mere2, answer: a2_15)
ParentsAnswer.create!(parent: mere2, answer: a3_yes)
ParentsAnswer.create!(parent: mere3, answer: a1_no)
ParentsAnswer.create!(parent: mere3, answer: a3_maybe)
puts "\t\t1 survey, 3 questions, 8 answers, 8 parents_answers ✓"

  # ===========================================================================
  # 15. EVENTS (TextMessage, OtherEvent, SurveyResponse, WorkshopParticipation)
  # ===========================================================================
puts "\tEvents"

  # SMS envoyes via SpotHit (differents statuts)
Events::TextMessage.create!(
  related: mere1, occurred_at: 3.weeks.ago,
  body: 'Bonjour ! Cette semaine, lisez un livre avec Lucas. https://app.1001mots.org/r/abc/12',
  originated_by_app: true, message_provider: 'spot_hit',
  spot_hit_status: 1, is_support_module_message: true
)
Events::TextMessage.create!(
  related: mere2, occurred_at: 2.weeks.ago,
  body: 'Bonjour ! Chantez avec Yasmine cette semaine.',
  originated_by_app: true, message_provider: 'spot_hit',
  spot_hit_status: 1, is_support_module_message: true
)
Events::TextMessage.create!(
  related: mere3, occurred_at: 1.week.ago,
  body: 'Bonjour ! Jouez avec Emma cette semaine.',
  originated_by_app: true, message_provider: 'spot_hit',
  spot_hit_status: 4 # Echec
)
Events::TextMessage.create!(
  related: mere5, occurred_at: 1.day.ago,
  body: 'Bonjour ! Comment allez-vous cette semaine ?',
  originated_by_app: true, message_provider: 'spot_hit',
  spot_hit_status: 0 # En attente
)

  # SMS recu (reponse parent)
Events::TextMessage.create!(
  related: mere1, occurred_at: 3.weeks.ago + 1.hour,
  body: 'Merci ! On a lu ensemble hier soir.', originated_by_app: false,
  message_provider: 'spot_hit'
)

  # SMS via Aircall
Events::TextMessage.create!(
  related: mere4, occurred_at: 2.weeks.ago,
  body: 'Rappel : votre prochain appel est prevu demain a 14h.',
  originated_by_app: true, message_provider: 'aircall'
)

  # Evenements autres
Events::OtherEvent.create!(
  related: mere1, occurred_at: 1.month.ago,
  subject: 'Appel de bienvenue', body: 'Premier contact effectue, famille motivee.'
)
Events::OtherEvent.create!(
  related: mere4, occurred_at: 2.weeks.ago,
  subject: 'Note de suivi', body: 'Parent difficile a joindre, 3 tentatives.'
)

  # Reponse enquete
Events::SurveyResponse.create!(
  related: mere1, occurred_at: 2.weeks.ago,
  body: 'Reponse complete au questionnaire de satisfaction.'
)
Events::SurveyResponse.create!(
  related: mere2, occurred_at: 2.weeks.ago,
  body: 'Reponse partielle.'
)

puts "\t\t10 events ✓"

  # ===========================================================================
  # 16. SCHEDULED CALLS
  # ===========================================================================
puts "\tScheduled Calls"

  # Appel prevu demain (test reminder next-day)
ScheduledCall.create!(
  calendly_event_uri: "https://api.calendly.com/scheduled_events/seed-#{SecureRandom.hex(8)}",
  admin_user: caller_user, parent: mere1, child_support: enfant1.child_support,
  scheduled_at: 1.day.from_now.change(hour: 14), status: 'scheduled',
  call_session: 1, duration_minutes: 30, event_type_name: 'Appel de suivi',
  invitee_email: 'marie.dupont@example.com', invitee_name: 'Marie Dupont',
  cancel_url: 'https://calendly.com/cancel/seed1'
)

  # Appel prevu dans 2h30 (test reminder same-day)
ScheduledCall.create!(
  calendly_event_uri: "https://api.calendly.com/scheduled_events/seed-#{SecureRandom.hex(8)}",
  admin_user: caller_user, parent: mere2, child_support: enfant2.child_support,
  scheduled_at: 150.minutes.from_now, status: 'scheduled',
  call_session: 2, duration_minutes: 30, event_type_name: 'Appel de suivi',
  invitee_email: 'fatima.benali@example.com', invitee_name: 'Fatima Benali',
  cancel_url: 'https://calendly.com/cancel/seed2'
)

  # Appel annule
ScheduledCall.create!(
  calendly_event_uri: "https://api.calendly.com/scheduled_events/seed-#{SecureRandom.hex(8)}",
  admin_user: caller_user, parent: mere3, child_support: enfant3.child_support,
  scheduled_at: 3.days.ago, status: 'canceled', canceled_at: 4.days.ago,
  cancellation_reason: 'Parent indisponible', call_session: 0,
  duration_minutes: 30, event_type_name: 'Appel de bienvenue',
  invitee_email: 'sophie.martin@example.com', invitee_name: 'Sophie Martin'
)

  # Appel passe
ScheduledCall.create!(
  calendly_event_uri: "https://api.calendly.com/scheduled_events/seed-#{SecureRandom.hex(8)}",
  admin_user: caller_user, parent: mere4, child_support: enfant4.child_support,
  scheduled_at: 1.week.ago, status: 'scheduled', call_session: 1,
  duration_minutes: 30, event_type_name: 'Appel de suivi',
  invitee_email: 'amina.diallo@example.com', invitee_name: 'Amina Diallo'
)
puts "\t\t4 scheduled calls ✓"

  # ===========================================================================
  # 17. AIRCALL CALLS
  # ===========================================================================
puts "\tAircall Calls"

AircallCall.create!(
  caller: caller_user, parent: mere1, child_support: enfant1.child_support,
  aircall_id: 100_001, call_uuid: SecureRandom.uuid,
  direction: 'outbound', answered: true,
  started_at: 3.weeks.ago, answered_at: 3.weeks.ago + 5.seconds,
  ended_at: 3.weeks.ago + 15.minutes, duration: 900, call_session: 0
)
AircallCall.create!(
  caller: caller_user, parent: mere2, child_support: enfant2.child_support,
  aircall_id: 100_002, call_uuid: SecureRandom.uuid,
  direction: 'outbound', answered: true,
  started_at: 2.weeks.ago, answered_at: 2.weeks.ago + 10.seconds,
  ended_at: 2.weeks.ago + 20.minutes, duration: 1200, call_session: 1
)
AircallCall.create!(
  caller: caller_user, parent: mere3,
  aircall_id: 100_003, call_uuid: SecureRandom.uuid,
  direction: 'outbound', answered: false,
  started_at: 1.week.ago, ended_at: 1.week.ago + 30.seconds,
  duration: 30, missed_call_reason: 'no_answer'
)
AircallCall.create!(
  caller: caller_user, parent: mere1,
  aircall_id: 100_004, call_uuid: SecureRandom.uuid,
  direction: 'inbound', answered: true,
  started_at: 1.week.ago, answered_at: 1.week.ago + 3.seconds,
  ended_at: 1.week.ago + 5.minutes, duration: 300
)
puts "\t\t4 aircall calls ✓"

  # ===========================================================================
  # 18. TASKS
  # ===========================================================================
puts "\tTasks"

Task.create!(
  title: 'Appeler la famille Dupont',
  description: 'Relancer la mere pour le prochain RDV',
  status: 'in_progress', reporter: contributor, assignee: caller_user,
  related: mere1, due_date: 1.week.from_now.to_date
)
Task.create!(
  title: 'Verifier adresse famille Diallo',
  description: 'Adresse suspectee invalide, a verifier avec la PMI',
  status: 'in_progress', reporter: admin, assignee: contributor,
  related: enfant4.child_support, due_date: 3.days.from_now.to_date
)
Task.create!(
  title: 'Preparer cohorte Orleans',
  description: 'Preparer les modules pour la cohorte future',
  status: 'done', reporter: admin, assignee: contributor,
  treated_by: contributor, done_at: 2.days.ago.to_date,
  due_date: 1.week.ago.to_date
)
puts "\t\t3 tasks ✓"

  # ===========================================================================
  # 19. FIELD COMMENTS
  # ===========================================================================
puts "\tField Comments"

FieldComment.create!(author: caller_user, related: enfant1.child_support, field: 'call0_notes', content: 'Parent tres implique, bonne ecoute.')
FieldComment.create!(author: caller_user, related: enfant3.child_support, field: 'call0_status', content: 'Impossible de joindre apres 3 tentatives.')
FieldComment.create!(author: contributor, related: mere4, field: 'address', content: 'Adresse verifiee par la PMI.')
puts "\t\t3 field comments ✓"

  # ===========================================================================
  # 20. PLACES
  # ===========================================================================
puts "\tPlaces"

Place.create!(place_type: 'laep', name: 'LAEP Les Petits Pas', address: '12 Rue de la Liberte, 75020 Paris', latitude: 48.8631, longitude: 2.3989, redirection_target: rt1)
Place.create!(place_type: 'laep', name: 'LAEP Bondy Centre', address: '8 Rue Auguste Blanqui, 93140 Bondy', latitude: 48.9022, longitude: 2.4835)
Place.create!(place_type: 'other', name: 'Mediatheque Orleans', address: '1 Place Gambetta, 45000 Orleans', latitude: 47.9029, longitude: 1.9039)
puts "\t\t3 places ✓"

  # ===========================================================================
  # 21. WORKSHOPS
  # ===========================================================================
puts "\tWorkshops"

  # NB: les callbacks after_create (select_recipients, send_message) se declenchent
  # mais sont sans effet en dev sans SpotHit configure
workshop1 = Workshop.new(
  animator: animator_user, topic: 'books',
  workshop_date: 3.weeks.from_now.to_date,
  location: 'LAEP Les Petits Pas', address: '12 Rue de la Liberte',
  postal_code: '75020', city_name: 'Paris', workshop_land: 'Paris 20 eme',
  invitation_message: 'Venez participer a notre atelier lecture !',
  first_workshop_time_slot: Time.zone.parse('10:00'),
  second_workshop_time_slot: Time.zone.parse('14:00')
)
workshop1.save!(validate: false)

workshop2 = Workshop.new(
  animator: animator_user, topic: 'games',
  workshop_date: 1.month.from_now.to_date,
  location: 'Mediatheque Bondy', address: '8 Rue Auguste Blanqui',
  postal_code: '93140', city_name: 'Bondy', workshop_land: 'Bondy',
  invitation_message: 'Atelier jeux et decouvertes !',
  first_workshop_time_slot: Time.zone.parse('09:30')
)
workshop2.save!(validate: false)

  # Atelier annule
workshop3 = Workshop.new(
  animator: animator_user, topic: 'nursery_rhymes',
  workshop_date: 2.weeks.from_now.to_date,
  location: 'Salle communale', address: '20 Rue Jeanne dArc',
  postal_code: '45000', city_name: 'Orleans',
  invitation_message: 'Atelier comptines (annule)', canceled: true,
  first_workshop_time_slot: Time.zone.parse('11:00')
)
workshop3.save!(validate: false)

  # Associations parents <-> workshops
workshop1.parents << mere1
workshop1.parents << mere2
workshop1.parents << mere3
workshop2.parents << mere4

  # Participations
Events::WorkshopParticipation.create!(
  related: mere1, workshop: workshop1, occurred_at: Time.zone.now,
  parent_presence: 'present', workshop_time_slot: 1
)
Events::WorkshopParticipation.create!(
  related: mere2, workshop: workshop1, occurred_at: Time.zone.now,
  parent_presence: 'planned_absence', workshop_time_slot: 1
)
Events::WorkshopParticipation.create!(
  related: mere3, workshop: workshop1, occurred_at: Time.zone.now,
  parent_presence: 'not_planned_absence', workshop_time_slot: 2
)
puts "\t\t3 workshops, 3 participations ✓"

  # ===========================================================================
  # 22. PARENTS REGISTRATIONS
  # ===========================================================================
puts "\tParents Registrations"

ParentsRegistration.create!(parent1: mere1, parent2: pere1, parent1_phone_number: '0800000000', parent2_phone_number: '0800000000', target_profile: true)
ParentsRegistration.create!(parent1: mere6, parent1_phone_number: '0800000000', target_profile: true)
puts "\t\t2 parents registrations ✓"

  # ===========================================================================
  # 23. TAGGINGS
  # ===========================================================================
puts "\tTaggings"

enfant2.tag_list.add('bilingue')
enfant2.save(validate: false)
enfant4.tag_list.add('bilingue')
enfant4.save(validate: false)
enfant7.tag_list.add('desengagement empeche')
enfant7.save(validate: false)
enfant11.tag_list.add('2eme cohorte')
enfant11.save(validate: false)
enfant9.tag_list.add('hors cible')
enfant9.save(validate: false)

mere3.tag_list.add('eval')
mere3.save(validate: false)

puts "\t\tTaggings appliques ✓"

  # ===========================================================================
  # 24. TEST DOUBLONS (donnees existantes preservees)
  # ===========================================================================
puts "\tTest doublons"

first_parent = FactoryBot.create(:parent, phone_number: '07800000000')
second_parent = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent = FactoryBot.create(:parent, phone_number: '07800000000')
child_with_parent2 = FactoryBot.create(:child, first_name: 'Andrea', last_name: 'Manon', parent1: first_parent, parent2: second_parent)
child_without_parent2 = FactoryBot.create(:child, first_name: 'andréA ', last_name: ' MaNon', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
dup_group = FactoryBot.create(:group, expected_children_number: 0)
child_with_parent2.update(group: dup_group, group_status: 'active')
child_without_parent2.update(group: dup_group, group_status: 'active')

first_parent = FactoryBot.create(:parent, phone_number: '07800000000')
second_parent = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent = FactoryBot.create(:parent, phone_number: '07800000000')
child_with_parent2 = FactoryBot.create(:child, first_name: 'Helene', last_name: 'Manitou', parent1: first_parent, parent2: second_parent)
child_without_parent2 = FactoryBot.create(:child, first_name: 'HélènE ', last_name: ' MaNiToU', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
dup_group1 = FactoryBot.create(:group, expected_children_number: 0)
dup_group2 = FactoryBot.create(:group, expected_children_number: 0)
child_with_parent2.update(group: dup_group1, group_status: 'active')
child_without_parent2.update(group: dup_group2, group_status: 'active')

first_parent = FactoryBot.create(:parent, phone_number: '07800000000')
second_parent = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent = FactoryBot.create(:parent, phone_number: '07800000000')
child_with_parent2 = FactoryBot.create(:child, first_name: 'Ana', last_name: 'Ninan', parent1: first_parent, parent2: second_parent)
child_without_parent2 = FactoryBot.create(:child, first_name: 'AnA ', last_name: ' NinAn', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
dup_group = FactoryBot.create(:group, expected_children_number: 0)
dup_group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
child_with_parent2.update(group: dup_group, group_status: 'active')

first_parent = FactoryBot.create(:parent, phone_number: '07800000000')
second_parent = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent = FactoryBot.create(:parent, phone_number: '07800000000')
child_with_parent2 = FactoryBot.create(:child, first_name: 'Anasthasie', last_name: 'Ninanto', parent1: first_parent, parent2: second_parent)
child_without_parent2 = FactoryBot.create(:child, first_name: 'AnAsThAsie ', last_name: ' NinAnTo', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent)
dup_group = FactoryBot.create(:group, expected_children_number: 0)
dup_group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
child_without_parent2.update(group: dup_group, group_status: 'active')

first_parent = FactoryBot.create(:parent, phone_number: '07800000000')
second_parent = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent1 = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent2 = FactoryBot.create(:parent, phone_number: '07800000000')
child1 = FactoryBot.create(:child, first_name: 'asie', last_name: 'anto', parent1: first_parent, parent2: second_parent)
child2 = FactoryBot.create(:child, first_name: 'Asie ', last_name: ' AnTo', birthdate: child1.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2)
dup_group = FactoryBot.create(:group, expected_children_number: 0)
dup_group2 = FactoryBot.create(:group, expected_children_number: 0)
child1.update(group: dup_group, group_status: 'active')
child2.update(group: dup_group2, group_status: 'active')

first_parent = FactoryBot.create(:parent, phone_number: '07800000000')
second_parent = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent1 = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_parent2 = FactoryBot.create(:parent, phone_number: '07800000000')
child1 = FactoryBot.create(:child, first_name: 'asTie', last_name: 'Ranto', parent1: first_parent, parent2: second_parent)
child2 = FactoryBot.create(:child, first_name: 'Astie ', last_name: ' rAnTo', birthdate: child1.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2)
dup_group = FactoryBot.create(:group, expected_children_number: 0)
dup_group2 = FactoryBot.create(:group, expected_children_number: 0)
dup_group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
child1.update(group: dup_group, group_status: 'active')
child2.update(group: dup_group2, group_status: 'active')

first_parent1 = FactoryBot.create(:parent, phone_number: '07800000000')
first_parent2 = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_first_parent1 = FactoryBot.create(:parent, phone_number: '07800000000')
duplicated_first_parent2 = FactoryBot.create(:parent, phone_number: '07800000000')
first_child = FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent1, parent2: first_parent2)
duplicated_first_child = FactoryBot.create(:child, first_name: 'duplicate Prenom ', last_name: 'duplicate Nom', parent1: duplicated_first_parent1, parent2: duplicated_first_parent2)

puts "\t\tTest doublons ✓"

puts '--- SEEDING COMPLETE ---'
