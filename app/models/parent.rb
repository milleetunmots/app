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
#  is_lycamobile                       :boolean
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

  has_many :parent1_children,
    class_name: :Child,
    foreign_key: :parent1_id,
    dependent: :nullify

  has_many :parent2_children,
    class_name: :Child,
    foreign_key: :parent2_id,
    dependent: :nullify

  def children
    parent1_children.or(parent2_children)
  end

  def first_child
    children.order(:id).first
  end

  has_many :redirection_urls, dependent: :destroy

  has_many :events, as: :related

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

  # ---------------------------------------------------------------------------
  # helpers
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

  def self.first_child_couples
    # Gets table of parent_id, first_child_id couples
    #
    # Make sure this is working properly with something like
    # Parent.first_child_couples.all? do |couple|
    #   Parent.find(couple['parent_id']).first_child&.id === couple['first_child_id']
    # end

    Parent.joins(
      "LEFT OUTER JOIN children
                    ON children.parent1_id = parents.id OR children.parent2_id = parents.id"
    ).group(
      :id
    ).select(
      "parents.id AS parent_id,
      MIN(children.id) AS first_child_id"
    )
  end

  def self.left_outer_joins_first_child
    # Joins with first_child, for example to extract group_id
    #
    # Make sure this is working with something like
    # Parent.left_outer_joins_first_child.select("parents.*, first_child.group_id").all? do |parent|
    #   parent.group_id == Parent.find(parent.id).first_child&.group_id
    # end

    joins(
      "INNER JOIN (#{first_child_couples.to_sql}) first_child_couples
               ON id = first_child_couples.parent_id"
    ).joins(
      "LEFT OUTER JOIN children first_child
                    ON first_child.id = first_child_couples.first_child_id"
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

  def self.where_first_child(conditions)
    left_outer_joins_first_child.where(first_child: conditions)
  end

  def self.first_child_group_id_in(*v)
    where_first_child(group_id: v)
  end

  def self.first_child_supported_by(v)
    where_first_child(child_support_id: ChildSupport.supported_by(v).select(:id))
  end

  def self.mothers
    where(gender: GENDER_FEMALE)
  end

  def self.fathers
    where(gender: GENDER_MALE)
  end

  def duplicate_of?(other_parent)
    return false if other_parent.nil?
    if other_parent.phone_number
      format_phone_number
      return true if phone_number == other_parent.phone_number
    end
    I18n.transliterate(first_name).capitalize == I18n.transliterate(other_parent.first_name).capitalize && I18n.transliterate(last_name).capitalize == I18n.transliterate(other_parent.last_name).capitalize
  end

  def specific_tags
    tag_list - first_child.all_tags
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
    if attribute_present?("phone_number")
      phone = Phonelib.parse(phone_number)
      self.phone_number = phone.e164
      self.phone_number_national = phone.national(false)
    end
  end

end
