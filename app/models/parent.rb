# == Schema Information
#
# Table name: parents
#
#  id                                  :bigint           not null, primary key
#  address                             :string           not null
#  address_supplement                  :string
#  aircall_datas                       :jsonb
#  book_delivery_location              :string
#  book_delivery_organisation_name     :string
#  city_name                           :string           not null
#  degree                              :string
#  degree_country_at_registration      :string
#  degree_in_france                    :boolean
#  degree_level_at_registration        :string
#  discarded_at                        :datetime
#  email                               :string
#  family_followed                     :boolean          default(FALSE)
#  first_name                          :string           not null
#  follow_us_on_whatsapp               :boolean
#  gender                              :string           not null
#  help_my_child_to_learn_is_important :string
#  is_ambassador                       :boolean
#  is_ambassador_detail                :text
#  is_excluded_from_workshop           :boolean          default(FALSE)
#  job                                 :string
#  last_name                           :string           not null
#  letterbox_name                      :string
#  mid_term_rate                       :integer
#  mid_term_reaction                   :string
#  mid_term_speech                     :text
#  phone_number                        :string           not null
#  phone_number_national               :string
#  postal_code                         :string           not null
#  preferred_channel                   :string
#  present_on_whatsapp                 :boolean
#  redirection_unique_visit_rate       :float
#  redirection_url_unique_visits_count :integer
#  redirection_url_visits_count        :integer
#  redirection_urls_count              :integer
#  redirection_visit_rate              :float
#  security_code                       :string
#  security_token                      :string
#  terms_accepted_at                   :datetime
#  would_like_to_do_more               :string
#  would_receive_advices               :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  aircall_id                          :string
#
# Indexes
#
#  index_parents_on_address                (address)
#  index_parents_on_city_name              (city_name)
#  index_parents_on_discarded_at           (discarded_at)
#  index_parents_on_email                  (email)
#  index_parents_on_first_name             (first_name)
#  index_parents_on_gender                 (gender)
#  index_parents_on_is_ambassador          (is_ambassador)
#  index_parents_on_job                    (job)
#  index_parents_on_last_name              (last_name)
#  index_parents_on_phone_number_national  (phone_number_national)
#  index_parents_on_postal_code            (postal_code)
#

class Parent < ApplicationRecord

  include Discard::Model
  include TagsSharedConcern

  attr_accessor :parent2_creation, :created_by_us

  DEGREE_LEVELS = %w[no_degree brevet bep_cap bac bac+1 bac+2 bac+3 bac+4 bac+5].freeze
  DEGREE_COUNTRIES = %w[france other].freeze
  GENDER_FEMALE = 'f'.freeze
  GENDER_MALE = 'm'.freeze
  GENDERS = [GENDER_FEMALE, GENDER_MALE].freeze
  ORELANS_POSTAL_CODE = %w[45000 45100 45140 45160 45380 45400 45430 45560 45590 45650 45750 45760 45770 45800 45520].freeze
  MONTARGIS_POSTAL_CODE = %w[45110 45120 45200 45210 45220 45230 45260 45270 45320 45490 45680 45700 49800 77460 77570].freeze
  AULNAY_SOUS_BOIS_POSTAL_CODE = %w[93600].freeze
  PARIS_20_EME_POSTAL_CODE = %w[75020].freeze
  BONDY_POSTAL_CODE = %w[93140].freeze
  GIEN_POSTAL_CODE = %w[45290 45500 45720 45250].freeze
  PITHIVIERS_POSTAL_CODE = %w[45300 45480 45170].freeze
  VILLENEUVE_LA_GARENNE_POSTAL_CODE = %w[92390].freeze
  ASNIERES_GENNEVILLIERS_POSTAL_CODE = %w[92600 92230].freeze
  COMMUNICATION_CHANNELS = %w[sms whatsapp].freeze
  BOOK_DELIVERY_LOCATION = %w[home relative_home pmi temporary_shelter association police_or_military_station].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :parent1_children, class_name: :Child, foreign_key: :parent1_id, dependent: :nullify
  has_many :parent2_children, class_name: :Child, foreign_key: :parent2_id, dependent: :nullify
  has_many :children, ->(parent) {
    unscope(:where).where("parent1_id = :id OR parent2_id = :id", id: parent.id)
  }
  has_many :redirection_urls, dependent: :destroy
  has_many :events, as: :related, dependent: :destroy
  has_many :children_support_modules, dependent: :destroy
  has_many :support_modules, through: :children_support_modules
  has_many :parents_answers, dependent: :destroy
  has_many :answers, through: :parents_answers
  has_and_belongs_to_many :workshops

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------
  before_save :format_phone_number
  before_save :reset_disabled_hidden_fields
  before_create :add_preferred_channel_tag, if: -> { preferred_channel.present? }
  after_create :should_be_contacted_as_parent2, if: -> { parent2_creation.present? }
  after_save :update_aircall_contact, if: -> { saved_change_to_discarded_at? && discarded_at.present? }
  after_save :change_the_other_parent_address, :should_not_contact_parent2
  after_save :change_child_support_address_suspected_invalid_at
  after_commit :create_aircall_contact, if: -> { created_by_us.present? }, on: :create
  after_validation :geocode, if: -> { address.present? && (address_changed? || city_name_changed? || postal_code_changed?) }

  validates :gender, presence: true, inclusion: { in: GENDERS }
  validates :first_name, presence: true
  validates :book_delivery_location, presence: true
  validates :letterbox_name, presence: true, if: -> { book_delivery_location.in? %w[home relative_home] }
  validates :first_name, format: { with: REGEX_VALID_NAME, allow_blank: true, message: INVALID_NAME_MESSAGE }
  validates :last_name, presence: true
  validates :last_name, format: { with: REGEX_VALID_NAME, allow_blank: true, message: INVALID_NAME_MESSAGE }
  validates :letterbox_name, format: { with: REGEX_VALID_ADDRESS, allow_blank: true, message: INVALID_ADDRESS_MESSAGE }
  validates :address, presence: true
  validates :address, format: { with: REGEX_VALID_ADDRESS, allow_blank: true, message: INVALID_ADDRESS_MESSAGE }
  validates :city_name, presence: true
  validates :postal_code, presence: true
  validates :postal_code, numericality: { only_integer: true }
  validates :postal_code, length: { is: 5 }
  validates :phone_number,
            phone: {
              possible: true,
              types: :mobile,
              countries: :fr,
              message: 'doit être composé de 10 chiffres'
            }
  validates :phone_number, presence: true
  validates :email,
            format: { with: REGEX_VALID_EMAIL, allow_blank: true, message: 'Les informations doivent être renseignées au format adresse email (xxxx@xx.com).' }
  validates :terms_accepted_at, presence: true
  validates :preferred_channel, inclusion: { in: COMMUNICATION_CHANNELS, allow_blank: true }
  validate :phone_number_format, on: :create
  validate :book_delivery_organisation_name_presence, if: -> { book_delivery_location.in?(%w[pmi temporary_shelter association police_or_military_station]) }

  geocoded_by :geocoder_address
  reverse_geocoded_by :latitude, :longitude

  scope :potential_duplicates, -> {
    where("parents.phone_number IN (SELECT phone_number FROM parents WHERE parents.discarded_at IS NULL GROUP BY parents.phone_number HAVING COUNT(*) > 1)")
  }
  scope :with_a_parent1_child_in_active_group, -> { joins(parent1_children: :group).where(parent1_children: { group_status: 'active' }).distinct }
  scope :with_a_parent2_child_in_active_group, -> { joins(parent2_children: :group).where(parent2_children: { group_status: 'active' }).distinct }
  scope :with_a_child_in_active_group, -> {
    joins("LEFT JOIN children parent1_children ON parents.id = parent1_children.parent1_id")
    .joins("LEFT JOIN children parent2_children ON parents.id = parent2_children.parent2_id")
    .where("(parent1_children.group_status = 'active' OR parent2_children.group_status = 'active')")
    .distinct
  }

  def initialize(attributes = {})
    super
    self.security_code = SecureRandom.hex(1)
    self.security_token = SecureRandom.hex(16)
    self.book_delivery_location = 'home' if book_delivery_location.blank?
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def update_counters!
    self.redirection_urls_count = redirection_urls.count

    if redirection_urls_count.zero?
      self.redirection_url_unique_visits_count = 0
      self.redirection_unique_visit_rate = 0
      self.redirection_url_visits_count = 0
      self.redirection_visit_rate = 0
    else
      self.redirection_url_unique_visits_count = redirection_urls.with_visits.count
      self.redirection_unique_visit_rate = redirection_url_unique_visits_count / redirection_urls_count.to_f
      self.redirection_url_visits_count = redirection_urls.sum(:redirection_url_visits_count)
      self.redirection_visit_rate = redirection_url_visits_count / redirection_urls_count.to_f
    end

    save!
  end

  def self.current_child_couples
    # Gets table of parent_id, current_child_id couples
    #
    # Make sure this is working properly with something like
    # Parent.current_child_couples.all? do |couple|
    #   Parent.find(couple['parent_id']).current_child&.id === couple['current_child_id']
    # end

    Parent.joins(
      "LEFT OUTER JOIN children
                    ON children.parent1_id = parents.id OR children.parent2_id = parents.id"
    ).group(
      :id
    ).select(
      "parents.id AS parent_id,
      MIN(children.id) AS current_child_id"
    )
  end

  def self.left_outer_joins_current_child
    # Joins with current_child, for example to extract group_id
    #
    # Make sure this is working with something like
    # Parent.left_outer_joins_current_child.select("parents.*, current_child.group_id").all? do |parent|
    #   parent.group_id == Parent.find(parent.id).current_child&.group_id
    # end

    joins(
      "INNER JOIN (#{current_child_couples.to_sql}) current_child_couples
               ON id = current_child_couples.parent_id"
    ).joins(
      "LEFT OUTER JOIN children current_child
                    ON current_child.id = current_child_couples.current_child_id"
    )
  end

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i[first_name last_name phone_number_national email security_token]

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  def self.where_current_child(conditions)
    left_outer_joins_current_child.where(current_child: conditions)
  end

  def self.current_child_group_id_in(*v)
    where_current_child(group_id: v)
  end

  def self.current_child_supported_by(v)
    where_current_child(child_support_id: ChildSupport.supported_by(v).select(:id))
  end

  def self.mothers
    where(gender: GENDER_FEMALE)
  end

  def self.fathers
    where(gender: GENDER_MALE)
  end

  def self.not_excluded_from_workshop
    where(is_excluded_from_workshop: false)
  end

  def self.excluded_from_workshop
    where(is_excluded_from_workshop: true)
  end

  def self.phone_numbers
    pluck(:phone_number)
  end

  def children
    parent1_children.or(parent2_children)
  end

  def current_child
    children.order(Arel.sql("CASE WHEN group_status = 'active' THEN 0 ELSE 1 END, birthdate DESC")).first
  end

  def duplicate_of?(other_parent)
    return false if other_parent.nil?

    if other_parent.phone_number
      format_phone_number
      return true if phone_number == other_parent.phone_number
    end
    I18n.transliterate(first_name).capitalize == I18n.transliterate(other_parent.first_name).capitalize && I18n.transliterate(last_name).capitalize == I18n.transliterate(other_parent.last_name).capitalize
  end

  def available_for_workshops?
    children.each { |child| return true if child.available_for_workshops }

    false
  end

  def should_be_contacted?
    parent1_children.each { |child| return false unless child.should_contact_parent1 }
    parent2_children.each { |child| return false unless child.should_contact_parent2 }

    true
  end

  def parent2_with_same_phone_number_as_parent1?
    return false if parent2_children.empty?

    parent2_children.each { |child| return true if child.parent1.phone_number == phone_number }
    false
  end

  def target_parent?
    return unless current_child.group

    current_child.target_child?
  end

  def children_name_and_birthdate
    children.kept.map(&:name_and_birthdate).sort_by { |name_and_birthdate| name_and_birthdate[:birthdate] }
  end

  def only_duplicated_children_with?(parent)
    children_name_and_birthdate.eql? parent.children_name_and_birthdate
  end

  def message_already_sent?(period, message_start)
    events.text_messages.where('originated_by_app = ? AND occurred_at > ? AND body ILIKE ?', true, period, "#{message_start}%").limit(1).any?
  end

  def attention_to
    return nil if book_delivery_location.in? [nil, 'home']

    return "Pour #{current_child.first_name} #{current_child.last_name}" if book_delivery_location == 'pmi'

    "Pour #{first_name} #{last_name}"
  end

  def book_delivery_location_different_from_home?
    book_delivery_location.in? %w[relative_home pmi temporary_shelter association police_or_military_station]
  end

  def reset_disabled_hidden_fields
    self.book_delivery_organisation_name = nil if book_delivery_location.in? %w[home relative_home]
    self.letterbox_name = nil if book_delivery_location.in? %w[pmi temporary_shelter association police_or_military_station]
  end

  def caf93?
    children.any? { |child| child.source&.name == 'CAF 93' }
  end

  def not_supported_children?
    children.all? { |child| child.group_status == 'not_supported' }
  end

  def waiting_children?
    children.all? { |child| child.group_status == 'waiting' }
  end

  def active_in_not_started_group_children?
    children.all? { |child| child.group_status == 'active' && child.group&.started_at&.future? }
  end

  def eval25_children?
    'Eval25 - 3 tentatives'.in?(tag_list) ||
      'Eval25 - impossible'.in?(tag_list) ||
      'Eval25 - refusée'.in?(tag_list)
  end



  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail skip: [:phone_number_national]

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

  private

  def book_delivery_organisation_name_presence
    return if book_delivery_organisation_name.present?
    return unless book_delivery_location.in?(%w[pmi temporary_shelter association police_or_military_station])

    label = case book_delivery_location
                when 'pmi'
                  'Nom de la PMI'
                when 'temporary_shelter'
                  "Nom complet de la structure d'accueil"
                when 'association'
                  "Nom complet de l'association"
                when 'police_or_military_station'
                  'Nom complet de la caserne ou du commissariat'
                end
    errors.add(label.to_sym, "doit être rempli")
  end


  def format_phone_number
    # format phone number to e164
    if attribute_present?('phone_number')
      phone = Phonelib.parse(phone_number)
      self.phone_number = phone.e164
      self.phone_number_national = phone.national(false)
    end
  end

  def should_not_contact_parent2
    parent2_children.select { |child| child.parent1.phone_number == phone_number }.each do |child|
      child.update_column(:should_contact_parent2, false)
    end
  end

  def add_preferred_channel_tag
    return unless self.preferred_channel.eql?('whatsapp')

    whatsapp_tag = Tag.find_or_create_by(name: 'whatsapp', is_visible_by_callers_and_animators: false)
    self.tag_list += [whatsapp_tag].flatten
  end

  def phone_number_format
    return unless attribute_present?('phone_number')

    phone = Phonelib.parse(phone_number)
    unless phone.valid_for_country?("FR") && phone.type == :mobile
      errors.add(:phone_number, "doit être un numéro de mobile français valide")
    end
  end

  def change_the_other_parent_address
    return unless saved_change_to_book_delivery_location? ||
                  saved_change_to_letterbox_name? ||
                  saved_change_to_address? ||
                  saved_change_to_postal_code? ||
                  saved_change_to_city_name? ||
                  saved_change_to_address_supplement? ||
                  saved_change_to_book_delivery_organisation_name?

    children.each do |child|
      p1 = child.parent1
      p2 = child.parent2
      change_address_attributes(p1) unless self == p1 || address_attributes_are_identical?(p1)
      if p2 && self != p2
        change_address_attributes(p2) unless address_attributes_are_identical?(p2)
      end
    end
  end

  def change_child_support_address_suspected_invalid_at
    return unless saved_change_to_letterbox_name? || saved_change_to_address? || saved_change_to_postal_code? || saved_change_to_city_name? || saved_change_to_address_supplement?

    children.each do |child|
      child_support = child.child_support
      next if child_support.address_suspected_invalid_at.nil?

      child_support.address_suspected_invalid_at = nil
      child_support.save(touch: false)
    end
  end

  def address_attributes_are_identical?(parent)
    parent.letterbox_name == letterbox_name &&
      parent.book_delivery_organisation_name == book_delivery_organisation_name &&
      parent.book_delivery_location == book_delivery_location &&
      parent.address == address &&
      parent.postal_code == postal_code &&
      parent.city_name == city_name &&
      parent.address_supplement == address_supplement
  end

  def change_address_attributes(parent)
    parent.update(
      book_delivery_location: book_delivery_location,
      letterbox_name: letterbox_name,
      book_delivery_organisation_name: book_delivery_organisation_name,
      address: address,
      postal_code: postal_code,
      city_name: city_name,
      address_supplement: address_supplement
    )
  end

  def should_be_contacted_as_parent2
    parent2_children.each do |child|
      child.should_contact_parent2 = true
      child.save
    end
  end

  def create_aircall_contact
    return unless ENV['AIRCALL_ENABLED']
    return unless created_by_us
    return unless current_child

    service = Aircall::CreateContactService.new(parent_id: id).call
    Rollbar.error('Aircall Contact creation error', parent_id: id, errors: service.errors) if service.errors.any?
  end

  def update_aircall_contact
    return unless ENV['AIRCALL_ENABLED']

    parent = Parent.kept.where(phone_number: phone_number).with_a_child_in_active_group.first
    return unless parent&.current_child


    service = Aircall::CreateContactService.new(parent_id: parent.id).call
    Rollbar.error('Aircall::CreateContactService', errors: service.errors, parent_id: parent.id) if service.errors.any?
  end

  def geocoder_address
    [address, postal_code, city_name].compact.join(', ')
  end
end
