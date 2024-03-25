# == Schema Information
#
# Table name: parents
#
#  id                                  :bigint           not null, primary key
#  address                             :string           not null
#  city_name                           :string           not null
#  degree                              :string
#  degree_in_france                    :boolean
#  discarded_at                        :datetime
#  email                               :string
#  family_followed                     :boolean          default(FALSE)
#  first_name                          :string           not null
#  follow_us_on_facebook               :boolean
#  follow_us_on_whatsapp               :boolean
#  gender                              :string           not null
#  help_my_child_to_learn_is_important :string
#  is_ambassador                       :boolean
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
#  present_on_facebook                 :boolean
#  present_on_whatsapp                 :boolean
#  redirection_unique_visit_rate       :float
#  redirection_url_unique_visits_count :integer
#  redirection_url_visits_count        :integer
#  redirection_urls_count              :integer
#  redirection_visit_rate              :float
#  security_code                       :string
#  terms_accepted_at                   :datetime
#  would_like_to_do_more               :string
#  would_receive_advices               :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
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

  GENDER_FEMALE = 'f'.freeze
  GENDER_MALE = 'm'.freeze
  GENDERS = [GENDER_FEMALE, GENDER_MALE].freeze
  ORELANS_POSTAL_CODE = %w[45000 45100 45140 45160 45380 45400 45430 45560 45590 45650 45750 45760 45770 45800 45520].freeze
  PLAISIR_POSTAL_CODE = %w[78390 78330 78370 78340 78450 78850].freeze
  MONTARGIS_POSTAL_CODE = %w[45110 45120 45200 45210 45220 45230 45260 45270 45320 45490 45680 45700 49800 77460 77570].freeze
  TRAPPES_POSTAL_CODE = %w[78190 78990].freeze
  AULNAY_SOUS_BOIS_POSTAL_CODE = %w[93600].freeze
  PARIS_18_EME_POSTAL_CODE = %w[75017 75018 75019].freeze
  PARIS_20_EME_POSTAL_CODE = %w[75020].freeze
  BONDY_POSTAL_CODE = %w[93140].freeze
  GIEN_POSTAL_CODE = %w[45290 45500 45720].freeze
  PITHIVIERS_POSTAL_CODE = %w[45300 45480 45170].freeze
  VILLENEUVE_LA_GARENNE_POSTAL_CODE = %w[92390].freeze
  MANTES_LA_JOLIE_POSTAL_CODE = %w[78520 78200].freeze
  ALL_POSTAL_CODE = ORELANS_POSTAL_CODE + PLAISIR_POSTAL_CODE + MONTARGIS_POSTAL_CODE + TRAPPES_POSTAL_CODE + PARIS_18_EME_POSTAL_CODE + AULNAY_SOUS_BOIS_POSTAL_CODE + PARIS_20_EME_POSTAL_CODE + BONDY_POSTAL_CODE


  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_many :parent1_children, class_name: :Child, foreign_key: :parent1_id, dependent: :nullify

  has_many :parent2_children, class_name: :Child, foreign_key: :parent2_id, dependent: :nullify

  has_many :redirection_urls, dependent: :destroy

  has_many :events, as: :related, dependent: :destroy

  has_many :children_support_modules, dependent: :destroy

  has_many :support_modules, through: :children_support_modules

  has_and_belongs_to_many :workshops

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  before_validation :format_phone_number

  validates :gender, presence: true, inclusion: { in: GENDERS }
  validates :first_name, presence: true
  validates :first_name, format: { with: REGEX_VALID_NAME, allow_blank: true, message: INVALID_NAME_MESSAGE }
  validates :last_name, presence: true
  validates :last_name, format: { with: REGEX_VALID_NAME, allow_blank: true, message: INVALID_NAME_MESSAGE }
  validates :letterbox_name, presence: true
  validates :letterbox_name, format: { with: REGEX_VALID_ADDRESS, allow_blank: true, message: INVALID_ADDRESS_MESSAGE }
  validates :address, presence: true
  validates :address, format: { with: REGEX_VALID_ADDRESS, allow_blank: true, message: INVALID_ADDRESS_MESSAGE }
  validates :city_name, presence: true
  validates :postal_code, presence: true
  validates :phone_number,
            phone: {
              possible: true,
              types: :mobile,
              countries: :fr,
              allow_blank: true,
              message: 'doit être composé de 10 chiffres'
            }
  validates :phone_number, presence: true
  validates :email,
            format: { with: REGEX_VALID_EMAIL, allow_blank: true, message: 'Les informations doivent être renseignées au format adresse email (xxxx@xx.com).' },
            uniqueness: { case_sensitive: false, allow_blank: true }
  validates :terms_accepted_at, presence: true

  scope :potential_duplicates, -> {
    where("parents.phone_number IN (SELECT phone_number FROM parents GROUP BY parents.phone_number HAVING COUNT(*) > 1)")
  }

  def initialize(attributes = {})
    super
    self.security_code = SecureRandom.hex(1)
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
  multisearchable against: %i[first_name last_name phone_number_national email]

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

  def target_parent?
    return unless current_child.group

    current_child.target_child?
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

  def format_phone_number
    # format phone number to e164
    if attribute_present?('phone_number')
      phone = Phonelib.parse(phone_number)
      self.phone_number = phone.e164
      self.phone_number_national = phone.national(false)
    end
  end
end
