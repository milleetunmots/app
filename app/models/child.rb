# == Schema Information
#
# Table name: children
#
#  id                                         :bigint           not null, primary key
#  birthdate                                  :date             not null
#  discarded_at                               :datetime
#  family_redirection_unique_visit_rate       :float
#  family_redirection_url_unique_visits_count :integer
#  family_redirection_url_visits_count        :integer
#  family_redirection_urls_count              :integer
#  family_redirection_visit_rate              :float
#  first_name                                 :string           not null
#  gender                                     :string
#  group_end                                  :date
#  group_start                                :date
#  group_status                               :string           default("waiting")
#  land                                       :string
#  last_name                                  :string           not null
#  pmi_detail                                 :string
#  registration_source                        :string
#  registration_source_details                :string
#  security_code                              :string
#  should_contact_parent1                     :boolean          default(FALSE), not null
#  should_contact_parent2                     :boolean          default(FALSE), not null
#  src_url                                    :string
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  family_id                                  :bigint           not null
#  group_id                                   :bigint
#
# Indexes
#
#  index_children_on_birthdate     (birthdate)
#  index_children_on_discarded_at  (discarded_at)
#  index_children_on_family_id     (family_id)
#  index_children_on_gender        (gender)
#  index_children_on_group_id      (group_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#

class Child < ApplicationRecord

  include Discard::Model

  after_commit :set_land, on: :create

  GENDERS = %w[m f].freeze
  REGISTRATION_SOURCES = %w[caf pmi friends therapist nursery doctor resubscribing other].freeze
  PMI_LIST = %w[trappes plaisir orleans orleans_est montargis gien pithiviers sarreguemines forbach].freeze
  GROUP_STATUS = %w[waiting active paused stopped].freeze
  LANDS = %w[Loiret Yvelines Seine-Saint-Denis Paris Moselle].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :group, optional: true
  belongs_to :family
  has_one :child_support, through: :family
  has_one :parent1, through: :family
  has_one :parent2, through: :family

  has_many :redirection_urls, dependent: :destroy # TODO: use nullify instead?

  accepts_nested_attributes_for :family
  accepts_nested_attributes_for :child_support
  accepts_nested_attributes_for :parent1
  accepts_nested_attributes_for :parent2

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :gender, inclusion: {in: GENDERS, allow_blank: true}
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true
  validates :birthdate, date: {
    after: proc { min_birthdate },
    before: proc { max_birthdate }
  }, on: :create
  validates :registration_source, presence: true, inclusion: {in: REGISTRATION_SOURCES}
  validates :registration_source_details, presence: true
  validates :security_code, presence: true
  validates :pmi_detail, inclusion: {in: PMI_LIST, allow_blank: true}
  validates :group_status, inclusion: {in: GROUP_STATUS}
  validates :land, inclusion: {in: LANDS, allow_blank: true}
  validate :no_duplicate, on: :create
  validate :different_phone_number, on: :create
  validate :valid_group_status

  delegate :tag_list,
           to: :family,
           allow_nil: true,
           prefix: true

  delegate :postal_code,
           to: :parent1

  def no_duplicate
    self.class.where('unaccent(first_name) ILIKE unaccent(?)', first_name).where(birthdate: birthdate).each do |child|
      if parent1.duplicate_of?(child.parent1) || parent1.duplicate_of?(child.parent2) || parent2&.duplicate_of?(child.parent1) || parent2&.duplicate_of?(child.parent2)
        errors.add(:base, :invalid, message: "L'enfant est déjà enregistré")
      end
    end
  end

  def different_phone_number
    return unless parent2&.phone_number
    if parent1.phone_number == parent2.phone_number
      errors.add(:base, :invalid, message: "Nous avons besoin des coordonnées d'au moins un parent. Si l'autre parent ne souhaite pas recevoir les messages, merci de ne pas l'inscrire car nous n'avons pas besoin de son nom.")
    end
  end

  def valid_group_status
    errors.add(:base, :invalid, message: "L'enfant ne peut pas être en attente en étant dans une cohorte") if group_id && group_status == "waiting"
    errors.add(:base, :invalid, message: "L'enfant doit être dans une cohorte") if group_id.nil? && group_status != "waiting"
  end

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  def initialize(attributes = {})
    super
    self.security_code = SecureRandom.hex(1)
  end

  def set_land
    case family.postal_code.to_i / 1000
    when 45 then update land: "Loiret"
    when 78 then update land: "Yvelines"
    when 93 then update land: "Seine-Saint-Denis"
    when 75 then update land: "Paris"
    when 57 then update land: "Moselle"
    end
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def self.min_birthdate
    Date.today - 48.months
  end

  def self.min_birthdate_alt
    Date.today - 2.years
  end

  def self.max_birthdate
    Date.today
  end

  # computes an (integer) number of months old
  def months
    duration_in_months(birthdate)
  end

  def registration_months
    duration_in_months(birthdate, created_at)
  end

  def child_group_months
    duration_in_months(group_start, group_end)
  end

  def months_between_registration_and_group_start
    duration_in_months(created_at, group_start)
  end

  def months_since_group_start
    return if group_end&.past?

    duration_in_months(group_start)
  end

  # ---------------------------------------------------------------------------
  # search by age (in months)
  # ---------------------------------------------------------------------------

  def self.months_gteq(x)
    # >= x months
    # means a birthdate at the most equal to x months ago
    where("birthdate <= ?", Time.zone.today - x.to_i.months)
  end

  def self.registration_months_gteq(x)
    where("age(children.created_at, birthdate) >= interval '? months'", x)
  end

  def self.months_lt(x)
    # < x months
    # means being at most 1 day less than x months old
    # which means a birthdate strictly greater than exactly x months ago
    where("birthdate > ?", Time.zone.today - x.to_i.months)
  end

  def self.registration_months_lt(x)
    where("age(children.created_at, birthdate) < interval '? months'", x)
  end

  def self.months_equals(x)
    months_gteq(x).merge(months_lt(x.to_i + 1))
  end

  def self.registration_months_equals(x)
    registration_months_gteq(x).merge(registration_months_lt(x.to_i + 1))
  end

  def self.months_between(x, y)
    months_gteq(x).merge(months_lt(y))
  end

  def self.registration_months_between(x, y)
    registration_months_gteq(x).merge(registration_months_lt(y))
  end

  def self.months_between_0_and_12
    months_between(0, 12)
  end

  def self.months_between_12_and_24
    months_between(12, 24)
  end

  def self.months_more_than_24
    months_gteq(24)
  end

  def self.family_tagged_with_all(*v)
    where(family: Family.tagged_with(v) )
  end

  # ---------------------------------------------------------------------------
  # other scopes
  # ---------------------------------------------------------------------------

  scope :with_group, -> { where.not(group_id: nil) }
  scope :without_group, -> { where(group_id: nil) }
  scope :without_group_and_not_waiting_second_group, -> { where(group_id: nil).where.not(id: all.select { |child| child.tag_list.include?("2eme cohorte") }.map(&:id)) }

  def self.postal_code_contains(v)
    where(family: Family.postal_code_contains(v))
  end

  def self.postal_code_ends_with(v)
    where(family: Family.postal_code_ends_with(v))
  end

  def self.postal_code_equals(v)
    where(family: Family.postal_code_equals(v))
  end

  def self.postal_code_starts_with(v)
    where(family: Family.postal_code_starts_with(v))
  end

  def self.with_parent_to_contact
    where(should_contact_parent1: true).or(where(should_contact_parent2: true))
  end

  def self.group_id_in(*v)
    where(group_id: v)
  end

  def self.active_group_id_in(*v)
    where(group_id: v).where(group_status: "active")
  end

  def self.registration_source_details_matches_any(*v)
    where("registration_source_details ILIKE ?", v)
  end

  def self.waiting_second_group
    where(id: all.select { |child| child.tag_list.include?("2eme cohorte") }.map(&:id))
  end

  def self.group_active_between(x, y)
    where("group_start >= ?", x).or(where("group_start >= ? AND group_end <= ?", x, y))
  end

  def parent_events
      Event.where(related_type: "Parent", related_id: [family.parent1_id, family.parent2_id].compact)
  end

  def self.parent_id_in(*v)
    where(family: Family.parent_id_in(v))
  end

  def self.parent_id_not_in(*v)
    where(family: Family.parent_id_not_in(v))
  end

  def self.without_parent_text_message_since(v)
    where(family: Family.without_parent_text_message_since(v))
  end

  # --------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    super + %i[months_equals months_gteq months_lt postal_code_contains postal_code_ends_with postal_code_equals postal_code_starts_with active_group_id_in without_parent_text_message_since registration_source_details_matches_any family_tagged_with_all]
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :name,
    to: :group,
    prefix: true,
    allow_nil: true

  def family_redirection_urls
    RedirectionUrl.where(parent_id: [family.parent1_id, family.parent2_id].compact)
  end

  def family_text_messages
    parent_events.text_messages
  end

  def family_text_messages_received
    parent_events.text_messages_send_by_app
  end

  def family_text_messages_sent
    parent_events.text_messages_send_by_parent
  end

  def update_counters!
    self.family_redirection_urls_count = family_redirection_urls.count("DISTINCT redirection_target_id")

    if family_redirection_urls_count.zero?
      self.family_redirection_url_unique_visits_count = 0
      self.family_redirection_unique_visit_rate = 0
      self.family_redirection_url_visits_count = 0
      self.family_redirection_visit_rate = 0
    else
      # family counters : if both parents receive a link and only
      # 1 parent opens it, we consider it 100% visited

      self.family_redirection_url_unique_visits_count = family_redirection_urls.with_visits.count("DISTINCT redirection_target_id")
      self.family_redirection_unique_visit_rate = family_redirection_url_unique_visits_count / family_redirection_urls_count.to_f
      self.family_redirection_url_visits_count = family_redirection_urls.sum(:redirection_url_visits_count)
      self.family_redirection_visit_rate = family_redirection_urls_count / family_redirection_urls_count.to_f
    end

    save!
  end

  def self.families_count
    Family.count
  end

  def self.parents
    parent_ids = Family.pluck(:parent1_id) + Family.pluck(:parent2_id)
    Parent.where(id: parent_ids.compact.uniq)
  end

  def self.fathers_count
    parents.fathers.count
  end

  # returns a Hash k => v where
  # - k is a possible value
  # - v is an Array of all corresponding values
  # e.g. { "Noémie" => ["Noémie", Noemie"] }
  def self.registration_source_details_map
    values = {}

    # input all values
    pluck(:registration_source_details).compact.uniq.each do |value|
      normalized_value = I18n.transliterate(
        value.unicode_normalize
      ).downcase.gsub(/[\s-]+/, " ").strip
      values[normalized_value] ||= []
      values[normalized_value] << value
    end

    # use first found value as map key and remove duplicates
    Hash[
      values.map do |k, v|
        [ v.first, v.uniq ]
      end
    ]
  end

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i[first_name last_name]

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

  private

  def duration_in_months(started_at, ended_at = Time.now)
    return unless started_at && ended_at && ended_at > started_at

    diff = ended_at.month + ended_at.year * 12 - (started_at.month + started_at.year * 12)
    if ended_at.day < started_at.day
      diff - 1
    else
      diff
    end
  end
end
