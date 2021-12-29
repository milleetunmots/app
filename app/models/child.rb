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
#  group_status                               :string          default("waiting"), not null
#  last_name                                  :string           not null
#  registration_source                        :string
#  registration_source_details                :string
#  security_code                              :string
#  should_contact_parent1                     :boolean          default(FALSE), not null
#  should_contact_parent2                     :boolean          default(FALSE), not null
#  src_url                                    :string
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  child_support_id                           :bigint
#  group_id                                   :bigint
#  parent1_id                                 :bigint           not null
#  parent2_id                                 :bigint
#
# Indexes
#
#  index_children_on_birthdate         (birthdate)
#  index_children_on_child_support_id  (child_support_id)
#  index_children_on_discarded_at      (discarded_at)
#  index_children_on_gender            (gender)
#  index_children_on_group_id          (group_id)
#  index_children_on_parent1_id        (parent1_id)
#  index_children_on_parent2_id        (parent2_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent1_id => parents.id)
#  fk_rails_...  (parent2_id => parents.id)
#

class Child < ApplicationRecord

  include Discard::Model

  after_commit :set_land, on: :create

  GENDERS = %w[m f].freeze
  REGISTRATION_SOURCES = %w[caf pmi friends therapist nursery resubscribing other].freeze
  PMI_LIST = %w[trappes plaisir orleans orleans_est montargis gien pithiviers sarreguemines forbach].freeze
  GROUP_STATUS = %w[waiting active paused stopped].freeze
  LANDS = %w[Loiret Yvelines Seine-Saint-Denis Paris Moselle].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :child_support, optional: true
  belongs_to :parent1, class_name: :Parent
  belongs_to :parent2, class_name: :Parent, optional: true
  belongs_to :group, optional: true

  has_many :redirection_urls, dependent: :destroy # TODO: use nullify instead?
  has_many :siblings, class_name: :Child, primary_key: :parent1_id, foreign_key: :parent1_id

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
  },
                        on: :create
  validates :registration_source, presence: true, inclusion: {in: REGISTRATION_SOURCES}
  validates :registration_source_details, presence: true
  validates :security_code, presence: true
  validates :pmi_detail, inclusion: {in: PMI_LIST, allow_blank: true}
  validates :group_status, inclusion: {in: GROUP_STATUS}
  validates :land, inclusion: {in: LANDS, allow_blank: true}
  validate :no_duplicate, on: :create
  validate :different_phone_number, on: :create
  validate :valid_group_status

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
    case postal_code.to_i / 1000
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
    diff = Time.zone.today.month + Time.zone.today.year * 12 - (birthdate.month + birthdate.year * 12)
    if Time.zone.today.day < birthdate.day
      diff - 1
    else
      diff
    end
  end

  def registration_months
    diff = created_at.month + created_at.year * 12 - (birthdate.month + birthdate.year * 12)
    if created_at.day < birthdate.day
      diff - 1
    else
      diff
    end
  end

  def child_group_months
    return unless group_end && group_start
    diff = group_end.month + group_end.year * 12 - (group_start.month + group_start.year * 12)
    if group_end.day < group_start.day
      diff - 1
    else
      diff
    end
  end

  # we do not call this 'siblings' because real siblings may have only
  # one parent in common
  def strict_siblings
    parent2_id ? self.class.where(parent1_id: parent1_id, parent2_id: parent2_id)
                     .or(self.class.where(parent1_id: parent2_id, parent2_id: parent1_id)).where.not(id: id) :
      self.class.where(parent1_id: parent1_id)
          .or(self.class.where(parent2_id: parent1_id)).where.not(id: id)
  end

  def true_siblings
    return [] if id.nil?
    if parent2_id
      self.class.where(parent1_id: parent1_id)
          .or(self.class.where(parent1_id: parent2_id))
          .or(self.class.where(parent2_id: parent1_id))
          .or(self.class.where(parent2_id: parent2_id)).where.not(id: id)
    else
      self.class.where(parent1_id: parent1_id)
          .or(self.class.where(parent2_id: parent1_id)).where.not(id: id)
    end
  end

  def all_tags
    tags = tag_list
    true_siblings.each { |child| tags = (tags + child.tag_list).uniq }
    tags
  end

  # ---------------------------------------------------------------------------
  # support
  # ---------------------------------------------------------------------------

  def create_support!(child_support_attributes = {tag_list: all_tags})
    # 1- create support
    child_support = ChildSupport.create!(child_support_attributes)

    # 2- use it on current child
    self.child_support_id = child_support.id
    self.tag_list = all_tags
    save(validate: false)

    # 3- also update all strict siblings
    # nb: we do this one by one to trigger paper_trail
    true_siblings.without_support.each do |child|
      child.child_support_id = child_support.id
      child.save(validate: false)
    end

    strict_siblings.each do |child|
      child.tag_list = all_tags
    end
  end

  # ---------------------------------------------------------------------------
  # search by age (in months)
  # ---------------------------------------------------------------------------

  def self.months_gteq(x)
    # >= x months
    # means a birthdate at the most equal to x months ago
    where("birthdate <= ?", Time.zone.today - x.to_i.months)
  end

  def self.months_lt(x)
    # < x months
    # means being at most 1 day less than x months old
    # which means a birthdate strictly greater than exactly x months ago
    where("birthdate > ?", Time.zone.today - x.to_i.months)
  end

  def self.months_equals(x)
    months_gteq(x).merge(months_lt(x.to_i + 1))
  end

  def self.months_between(x, y)
    months_gteq(x).merge(months_lt(y))
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

  # ---------------------------------------------------------------------------
  # other scopes
  # ---------------------------------------------------------------------------

  scope :with_support, -> { joins(:child_support) }

  def self.without_support
    left_outer_joins(:child_support).where(child_supports: {id: nil})
  end

  def self.postal_code_contains(v)
    where(parent1: Parent.ransack(postal_code_contains: v).result)
  end

  def self.postal_code_ends_with(v)
    where(parent1: Parent.ransack(postal_code_ends_with: v).result)
  end

  def self.postal_code_equals(v)
    where(parent1: Parent.ransack(postal_code_equals: v).result)
  end

  def self.postal_code_starts_with(v)
    where(parent1: Parent.ransack(postal_code_starts_with: v).result)
  end

  scope :with_group, -> { where.not(group_id: nil) }
  scope :without_group, -> { where(group_id: nil) }
  scope :without_group_and_not_waiting_second_group, -> { where(group_id: nil).where.not(id: all.select { |child| child.tag_list.include?("2eme cohorte") }.map(&:id)) }

  def self.with_parent_to_contact
    where(should_contact_parent1: true).or(where(should_contact_parent2: true))
  end

  def self.parent_id_in(*v)
    where(parent1_id: v).or(where(parent2_id: v))
  end

  def self.parent_id_not_in(*v)
    where.not(parent1_id: v).where.not(parent2_id: v)
  end

  def self.without_parent_to_contact
    # info: AR simplifies this
    where(should_contact_parent1: [nil, false], should_contact_parent2: [nil, false])
      .or(where(should_contact_parent1: [nil, false], should_contact_parent2: true, parent2_id: nil))
  end

  def self.group_id_in(*v)
    where(group_id: v)
  end

  def self.active_group_id_in(*v)
    where(group_id: v).where(group_status: "active")
  end

  def self.without_parent_text_message_since(v)
    parent_id_not_in(
      Events::TextMessage.where(related_type: :Parent).where("occurred_at >= ?", v).pluck("DISTINCT related_id")
    )
  end

  def self.registration_source_details_matches_any(*v)
    where("registration_source_details ILIKE ?", v)
  end

  def self.waiting_second_group
    where(id: all.select { |child| child.tag_list.include?("2eme cohorte") }.map(&:id))
  end

  # --------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    super + %i[months_equals months_gteq months_lt postal_code_contains postal_code_ends_with postal_code_equals postal_code_starts_with active_group_id_in without_parent_text_message_since registration_source_details_matches_any]
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :email,
    :first_name,
    :last_name,
    :gender,
    :phone_number_national,
    to: :parent1,
    prefix: true

  delegate :email,
    :first_name,
    :last_name,
    :gender,
    :phone_number_national,
    to: :parent2,
    prefix: true,
    allow_nil: true

  delegate :address,
    :city_name,
    :letterbox_name,
    :postal_code,
    to: :parent1

  delegate :is_ambassador,
    :is_ambassador?,
    :is_lycamobile,
    :is_lycamobile?,
    to: :parent1,
    prefix: true

  delegate :is_ambassador,
    :is_ambassador?,
    :is_lycamobile,
    :is_lycamobile?,
    to: :parent2,
    prefix: true,
    allow_nil: true

  delegate :name,
    to: :group,
    prefix: true,
    allow_nil: true

  def family_redirection_urls
    RedirectionUrl.where(parent_id: [parent1_id, parent2_id].compact)
  end

  def family_text_messages
    parent_events.text_messages
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

  def parent_events
    Event.where(related_type: "Parent", related_id: [parent1_id, parent2_id].compact)
  end

  def self.families_count
    count("DISTINCT parent1_id")
  end

  def self.parents
    parent_ids = pluck(:parent1_id) + pluck(:parent2_id)
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

end
