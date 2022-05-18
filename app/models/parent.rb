# == Schema Information
#
# Table name: parents
#
#  id                                  :bigint           not null, primary key
#  address                             :string           not null
#  city_name                           :string           not null
#  discarded_at                        :datetime
#  email                               :string
#  first_name                          :string           not null
#  gender                              :string           not null
#  is_ambassador                       :boolean
#  job                                 :string
#  last_name                           :string           not null
#  letterbox_name                      :string
#  phone_number                        :string           not null
#  phone_number_national               :string
#  postal_code                         :string           not null
#  redirection_unique_visit_rate       :float
#  redirection_url_unique_visits_count :integer
#  redirection_url_visits_count        :integer
#  redirection_urls_count              :integer
#  redirection_visit_rate              :float
#  terms_accepted_at                   :datetime
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

  GENDER_FEMALE = "f".freeze
  GENDER_MALE = "m".freeze
  GENDERS = [GENDER_FEMALE, GENDER_MALE].freeze
  REGEX_VALID_EMAIL = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_one :family, ->(parent){ unscope(:where).where('parent1_id = ? OR parent2_id = ?', parent.id, parent.id) }
  has_many :children, through: :family
  has_many :events, as: :related
  has_many :workshops, through: :events
  has_many :redirection_urls, dependent: :destroy


  accepts_nested_attributes_for :family

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  before_validation :format_phone_number

  validates :gender, presence: true, inclusion: {in: GENDERS}
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :letterbox_name, presence: true
  validates :address, presence: true
  validates :city_name, presence: true
  validates :postal_code, presence: true
  validates :phone_number,
    phone: {
      possible: true,
      types: :mobile,
      countries: :fr
    },
    presence: true
  validates :email,
    format: {with: REGEX_VALID_EMAIL, allow_blank: true},
    uniqueness: {case_sensitive: false, allow_blank: true}
  validates :terms_accepted_at, presence: true

  delegate :tag_list, to: :family, prefix: true

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i[first_name last_name phone_number_national email]

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  def self.mothers
    where(gender: GENDER_FEMALE)
  end

  def self.fathers
    where(gender: GENDER_MALE)
  end

  def children
    family&.children
  end

  def duplicate_of?(other_parent)
    return false if other_parent.nil?

    if other_parent.phone_number
      format_phone_number
      return true if phone_number == other_parent.phone_number
    end
    I18n.transliterate(first_name).capitalize == I18n.transliterate(other_parent.first_name).capitalize && I18n.transliterate(last_name).capitalize == I18n.transliterate(other_parent.last_name).capitalize
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail skip: [:phone_number_national]

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

  # ---------------------------------------------------------------------------
  # methods
  # ---------------------------------------------------------------------------

  def update_counters!
    self.redirection_urls_count = redirection_urls.count

    if self.redirection_urls_count.zero?
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

  private

  def format_phone_number
    # format phone number to e164
    if attribute_present?("phone_number")
      phone = Phonelib.parse(phone_number)
      self.phone_number = phone.e164
      self.phone_number_national = phone.national(false)
    end
  end
end
