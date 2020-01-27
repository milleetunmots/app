# == Schema Information
#
# Table name: children
#
#  id                                         :bigint           not null, primary key
#  birthdate                                  :date             not null
#  family_redirection_unique_visit_rate       :float
#  family_redirection_url_unique_visits_count :integer
#  family_redirection_url_visits_count        :integer
#  family_redirection_urls_count              :integer
#  family_redirection_visit_rate              :float
#  first_name                                 :string           not null
#  gender                                     :string
#  has_quit_group                             :boolean
#  last_name                                  :string           not null
#  registration_source                        :string
#  registration_source_details                :string
#  should_contact_parent1                     :boolean          default(FALSE), not null
#  should_contact_parent2                     :boolean          default(FALSE), not null
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

  GENDERS = %w[m f].freeze
  REGISTRATION_SOURCES = %w[
    pmi
    friends
    therapist
    nursery
    resubscribing
    other
  ].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :child_support, optional: true
  belongs_to :parent1, class_name: :Parent
  belongs_to :parent2, class_name: :Parent, optional: true
  belongs_to :group, optional: true

  has_many :redirection_urls, dependent: :destroy # TODO: use nullify instead?
  has_many :siblings, class_name: :Child, primary_key: :parent1_id, foreign_key: :parent1_id

  # we do not call this 'siblings' because real siblings may have only
  # one parent in common
  def strict_siblings
    self.class.where(parent1_id: parent1_id, parent2_id: parent2_id).where.not(id: id)
  end

  accepts_nested_attributes_for :child_support
  accepts_nested_attributes_for :parent1
  accepts_nested_attributes_for :parent2

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :gender, inclusion: { in: GENDERS, allow_blank: true }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true
  validates :registration_source, presence: true, inclusion: { in: REGISTRATION_SOURCES }
  validates :registration_source_details, presence: true

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  # computes an (integer) number of months old
  def months
    diff = Time.zone.today.month + Time.zone.today.year * 12 - (birthdate.month + birthdate.year * 12)
    if Time.zone.today.day < birthdate.day
      diff - 1
    else
      diff
    end
  end

  # ---------------------------------------------------------------------------
  # support
  # ---------------------------------------------------------------------------

  def create_support!(child_support_attributes = {})
    # 1- create support
    child_support = ChildSupport.create!(child_support_attributes)

    # 2- use it on current child
    self.child_support_id = child_support.id
    self.save(validate: false)

    # 3- also update all strict siblings
    # nb: we do this one by one to trigger paper_trail
    strict_siblings.without_support.each do |child|
      child.child_support_id = child_support.id
      child.save(validate: false)
    end
  end

  # ---------------------------------------------------------------------------
  # search by age (in months)
  # ---------------------------------------------------------------------------

  def self.months_gteq(x)
    # >= x months
    # means a birthdate at the most equal to x months ago
    where('birthdate <= ?', Time.zone.today - x.to_i.months)
  end

  def self.months_lt(x)
    # < x months
    # means being at most 1 day less than x months old
    # which means a birthdate strictly greater than exactly x months ago
    where('birthdate > ?', Time.zone.today - x.to_i.months)
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

  def self.months_between_24_and_36
    months_between(24, 36)
  end

  def self.months_more_than_36
    months_gteq(36)
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

  def self.with_parent_to_contact
    where(should_contact_parent1: true).or(
      where(should_contact_parent2: true)
    )
  end

  def self.without_parent_to_contact
    # info: AR simplifies this
    where(
      should_contact_parent1: [nil, false],
      should_contact_parent2: [nil, false]
    ).or(
      where(
        should_contact_parent1: [nil, false],
        should_contact_parent2: true,
        parent2_id: nil
      )
    )
  end

  def self.unpaused_group_id_in(*v)
    where(group_id: v).where.not(has_quit_group: true)
  end

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    %i(months_equals months_gteq months_lt postal_code_contains postal_code_ends_with postal_code_equals postal_code_starts_with unpaused_group_id_in)
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :first_name,
           :last_name,
           :gender,
           :phone_number_national,
           to: :parent1,
           prefix: true

  delegate :first_name,
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

  delegate :is_ambassador?,
           :is_lycamobile?,
           to: :parent1,
           prefix: true

  delegate :is_ambassador?,
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

  def update_counters!
    self.family_redirection_urls_count = family_redirection_urls.count('DISTINCT redirection_target_id')

    if self.family_redirection_urls_count.zero?
      self.family_redirection_url_unique_visits_count = 0
      self.family_redirection_unique_visit_rate = 0
      self.family_redirection_url_visits_count = 0
      self.family_redirection_visit_rate = 0
    else
      # family counters : if both parents receive a link and only
      # 1 parent opens it, we consider it 100% visited

      self.family_redirection_url_unique_visits_count = family_redirection_urls.with_visits.count('DISTINCT redirection_target_id')
      self.family_redirection_unique_visit_rate = family_redirection_url_unique_visits_count / family_redirection_urls_count.to_f
      self.family_redirection_url_visits_count = family_redirection_urls.sum(:redirection_url_visits_count)
      self.family_redirection_visit_rate = family_redirection_urls_count / family_redirection_urls_count.to_f
    end

    save!
  end

  def parent_events
    Event.where(
      related_type: 'Parent',
      related_id: [parent1_id, parent2_id].compact
    )
  end

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i(first_name last_name)

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
