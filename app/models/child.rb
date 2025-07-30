# == Schema Information
#
# Table name: children
#
#  id                                         :bigint           not null, primary key
#  available_for_workshops                    :boolean          default(FALSE)
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
#  last_name                                  :string           not null
#  pmi_detail                                 :string
#  registration_source                        :string
#  registration_source_details                :string
#  security_code                              :string
#  security_token                             :string
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

  attr_accessor :parent1_selection, :parent2_selection

  GENDERS = %w[m f].freeze
  GROUP_STATUS = %w[waiting active paused stopped disengaged not_supported].freeze
  TERRITORIES = %w[Loiret Yvelines Seine-Saint-Denis Paris Moselle].freeze
  LANDS = {
      'Paris 18 eme' => Parent::PARIS_18_EME_POSTAL_CODE,
      'Paris 20 eme' => Parent::PARIS_20_EME_POSTAL_CODE,
      'Plaisir' => Parent::PLAISIR_POSTAL_CODE,
      'Bondy' => Parent::BONDY_POSTAL_CODE,
      'Trappes' => Parent::TRAPPES_POSTAL_CODE,
      'Aulnay sous bois' => Parent::AULNAY_SOUS_BOIS_POSTAL_CODE,
      'Orleans' => Parent::ORELANS_POSTAL_CODE,
      'Montargis' => Parent::MONTARGIS_POSTAL_CODE,
      'Gien' => Parent::GIEN_POSTAL_CODE,
      'Pithiviers' => Parent::PITHIVIERS_POSTAL_CODE,
      'Villeneuve-la-Garenne' => Parent::VILLENEUVE_LA_GARENNE_POSTAL_CODE,
      'Mantes La Jolie' => Parent::MANTES_LA_JOLIE_POSTAL_CODE,
      'Asnières-Gennevilliers' => Parent::ASNIERES_GENNEVILLIERS_POSTAL_CODE
    }

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i[first_name last_name]
  pg_search_scope :kinda_spelled_like,
                  against: %i[first_name last_name],
                  using: { trigram: { threshold: ENV['CHILD_DUPLICATE_TREE_HOLD'].to_f } },
                  ignoring: :accents

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :child_support, optional: true
  belongs_to :parent1, class_name: :Parent
  belongs_to :parent2, class_name: :Parent, optional: true
  belongs_to :group, optional: true

  has_many :redirection_urls, dependent: :destroy # TODO: use nullify instead?
  has_many :siblings, class_name: :Child, primary_key: :parent1_id, foreign_key: :parent1_id
  has_many :children_support_modules, dependent: :destroy

  has_one :supporter, through: :child_support, class_name: :AdminUser
  has_one :children_source
  has_one :source, through: :children_source

  accepts_nested_attributes_for :child_support
  accepts_nested_attributes_for :parent1
  accepts_nested_attributes_for :parent2
  accepts_nested_attributes_for :children_source
  accepts_nested_attributes_for :children_support_modules


  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :gender, inclusion: { in: GENDERS, allow_blank: true }
  validates :first_name, presence: true
  validates :first_name, format: { with: REGEX_VALID_NAME, allow_blank: true, message: INVALID_NAME_MESSAGE }
  validates :last_name, presence: true
  validates :last_name, format: { with: REGEX_VALID_NAME, allow_blank: true, message: INVALID_NAME_MESSAGE }
  validates :birthdate, presence: true
  validates :birthdate, date: {
    after: proc { min_birthdate },
    before: proc { max_birthdate }
  }, on: :create
  validates :security_code, presence: true
  validates :group_status, inclusion: { in: GROUP_STATUS }
  # validate :no_duplicate, on: :create
  # validate :different_phone_number, on: :create
  validate :valid_group_status

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  def initialize(attributes = {})
    super
    self.security_code = SecureRandom.hex(1)
    self.security_token = SecureRandom.hex(16)
  end

  before_update do
    unless (tag_list - parent1.tag_list).empty?
      parent1.tag_list.add(tag_list)
      parent1.save
    end

    if parent2 && !(tag_list - parent2&.tag_list).empty?
      parent2&.tag_list&.add(tag_list)
      parent2&.save
    end
  end

  after_create :create_support!
  after_commit :add_to_group, on: :create
  after_update :update_support
  after_save { tags.where(is_visible_by_callers: true).where('name ILIKE ?', 'utm%').update(is_visible_by_callers: false) }
  after_update :remove_group, if: -> { saved_change_to_group_status? && group_status.eql?('not_supported') }
  after_commit :clean_child_support, if: -> { saved_change_to_child_support_id? }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :with_support, -> { joins(:child_support) }
  scope :without_support, -> { where(child_support_id: nil) }
  scope :with_group, -> { where.not(group_id: nil) }
  scope :with_stopped_group, -> { where.not(group_id: nil).where(group_status: 'stopped') }
  scope :without_group, -> { where(group_id: nil) }
  scope :available_for_the_workshops, -> { where(available_for_workshops: true) }
  scope :active_group, -> { where(group_status: 'active') }
  scope :only_siblings, -> { where(child_support_id: ChildSupport.multiple_children.select(:id)) }
  scope :no_siblings, -> { where(child_support_id: ChildSupport.one_child.select(:id)) }
  scope :with_ongoing_group, -> { joins(:group).merge(Group.started) }
  scope :potential_duplicates, -> {
    where('(TRIM(LOWER(unaccent(children.first_name))), TRIM(LOWER(unaccent(children.last_name))),children.birthdate)
            IN (SELECT TRIM(LOWER(unaccent(first_name))),TRIM(LOWER(unaccent(last_name))),birthdate
                FROM children WHERE (children.discarded_at IS NULL) GROUP BY TRIM(LOWER(unaccent(children.first_name))), TRIM(LOWER(unaccent(children.last_name))), children.birthdate HAVING COUNT(*) > 1)')
  }
  scope :potential_duplicates_by_phone_number, -> {
    left_outer_joins(:parent1, :parent2).merge(Parent.potential_duplicates)
  }
  scope :potential_duplicates_by_phone_number_without_same_parents, -> {
    joins("LEFT JOIN parents AS parent1 ON parent1.id = children.parent1_id")
    .joins("LEFT JOIN parents AS parent2 ON parent2.id = children.parent2_id")
    .where.not('parent1.phone_number_national ILIKE ?', "%#{ENV['FAKE_NUMBER']}%")
    .where(<<~SQL)
      (
        parent1.phone_number_national IN (
          SELECT phone_number_national
          FROM parents
          WHERE parents.discarded_at IS NULL
          GROUP BY parents.phone_number_national
          HAVING COUNT(*) > 1
        )
        OR parent2.phone_number_national IN (
          SELECT phone_number_national
          FROM parents
          WHERE parents.discarded_at IS NULL
          GROUP BY parents.phone_number_national
          HAVING COUNT(*) > 1
        )
      )
      AND NOT EXISTS (
        SELECT 1 FROM parents p
        WHERE p.phone_number_national = parent1.phone_number_national
        AND p.phone_number_national = parent2.phone_number_national
        AND p.discarded_at IS NULL
        GROUP BY p.phone_number_national
        HAVING COUNT(*) = 2
      )
    SQL
  }
  scope :supported, -> { where.not(group_status: 'not_supported') }
  scope :with_group_not_started, -> {where(id: left_outer_joins(:group).where('groups.started_at >= ? AND groups.support_module_programmed = ?', Time.zone.today, 0).select(:id)) }
  scope :waiting_children, -> { where(group_status: 'waiting') }
  scope :pending_support, -> { with_group_not_started.or(waiting_children) }
  scope :not_pending_support, -> { with_group.where.not(id: pending_support) }

  def self.without_group_and_not_waiting_second_group
    second_group_children_ids = Child.tagged_with('2eme cohorte').pluck(:id)
    where(group_id: nil).where.not(id: second_group_children_ids)
  end

  def self.waiting_second_group
    waiting_second_group_children_ids = Child.tagged_with('2eme cohorte').pluck(:id)
    where(id: waiting_second_group_children_ids)
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

  def self.supporter_id_in(*v)
    joins(:child_support).where(child_supports: { supporter_id: v })
  end

  def self.group_id_in(*v)
    where(group_id: v)
  end

  def self.active_group_id_in(*v)
    where(group_id: v).where(group_status: 'active')
  end

  def self.source_id_in(*v)
    joins(:children_source).where(children_sources: { source_id: v })
  end

  def self.source_channel_in(*v)
    joins(:source).where(sources: { channel: v })
  end

  def self.source_details_matches_any(*v)
    joins(:children_source).where(children_sources: { details: v })
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

  def self.registration_months_gteq(x)
    where("age(children.created_at, birthdate) >= interval '? months'", x)
  end

  def self.registration_months_lt(x)
    where("age(children.created_at, birthdate) <= interval '? months'", x)
  end

  def self.registration_months_equals(x)
    registration_months_gteq(x).merge(registration_months_lt(x.to_i + 1))
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

  def self.months_between_6_and_12
    months_between(6, 12)
  end

  def self.months_between_12_and_18
    months_between(12, 18)
  end

  def self.months_between_18_and_24
    months_between(18, 24)
  end

  def self.four_to_ten
    months_between(4, 11).where(group_status: 'active')
  end

  def self.eleven_to_sixteen
    months_between(11, 17).where(group_status: 'active')
  end

  def self.seventeen_to_twenty_two
    months_between(17, 23).where(group_status: 'active')
  end

  def self.twenty_three_and_more
    months_gteq(23).where(group_status: 'active')
  end

  def self.less_than_five
    months_lt(5).where(group_status: 'active')
  end

  def self.five_to_eleven
    months_between(5, 12).where(group_status: 'active')
  end

  def self.twelve_to_seventeen
    months_between(12, 18).where(group_status: 'active')
  end

  def self.eighteen_to_twenty_three
    months_between(18, 24).where(group_status: 'active')
  end

  def self.twenty_four_to_twenty_nine
    months_between(24, 30).where(group_status: 'active')
  end

  def self.thirty_to_thirty_five
    months_between(30, 36).where(group_status: 'active')
  end

  def self.thirty_six_to_forty
    months_between(36, 41).where(group_status: 'active')
  end

  def self.forty_one_to_forty_four
    months_between(41, 44).where(group_status: 'active')
  end

  def self.more_than_thirty_six
    months_gteq(36).where(group_status: 'active')
  end

  def self.more_than_thirty_five
    months_gteq(35).where(group_status: 'active')
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def self.min_birthdate
    Time.zone.today - 30.months
  end

  def self.min_birthdate_alt
    Time.zone.today - 2.years
  end

  def self.max_birthdate
    Time.zone.today
  end

  def self.families_count
    count('DISTINCT children.parent1_id')
  end

  def self.fathers_count
    parents.fathers.count
  end

  def self.parents
    parent_ids = pluck(:parent1_id) + pluck(:parent2_id)
    Parent.where(id: parent_ids.compact.uniq)
  end

  def self.parents_phone_numbers
    parents.phone_numbers.uniq
  end

  def self.max_birthdate_36_months
    36.months.ago.to_date
  end

  # ---------------------------------------------------------------------------
  # methods
  # ---------------------------------------------------------------------------

  delegate :email,
           :first_name,
           :last_name,
           :gender,
           :phone_number_national,
           :book_delivery_organisation_name,
           :attention_to,
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
           :address_supplement,
           :city_name,
           :letterbox_name,
           :postal_code,
           :book_delivery_location,
           :book_delivery_organisation_name,
           to: :parent1

  delegate :is_ambassador,
           :is_ambassador?,
           :present_on_whatsapp,
           :present_on_whatsapp?,
           :follow_us_on_whatsapp,
           :follow_us_on_whatsapp?,
           to: :parent1,
           prefix: true

  delegate :is_ambassador,
           :is_ambassador?,
           :present_on_whatsapp,
           :present_on_whatsapp?,
           :follow_us_on_whatsapp,
           :follow_us_on_whatsapp?,
           to: :parent2,
           prefix: true,
           allow_nil: true

  delegate :name,
           :enable_calls_recording,
           to: :group,
           prefix: true,
           allow_nil: true

  delegate :id,
           to: :child_support,
           prefix: true,
           allow_nil: true

  delegate :name, :details, to: :children_source, prefix: true, allow_nil: true

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

  # we do not call this 'siblings' because real siblings may have only
  # one parent in common
  def strict_siblings
    if parent2_id
      self.class.where(parent1_id: parent1_id, parent2_id: parent2_id)
          .or(self.class.where(parent1_id: parent2_id, parent2_id: parent1_id)).where.not(id: id)
    else
      self.class.where(parent1_id: parent1_id)
          .or(self.class.where(parent2_id: parent1_id)).where.not(id: id)
    end
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

  def youngest_sibling
    siblings.order(:birthdate).last
  end

  def self.first_active_group
    active_group.first&.group
  end

  def family_redirection_urls
    RedirectionUrl.where(parent_id: [parent1_id, parent2_id].compact)
  end

  def family_text_messages
    parent_events.text_messages
  end

  def family_text_messages_received
    parent_events.sent_by_app_text_messages
  end

  def family_text_messages_sent
    parent_events.received_text_messages
  end

  def update_counters!
    self.family_redirection_urls_count = family_redirection_urls.count('DISTINCT redirection_target_id')

    if family_redirection_urls_count.zero?
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
    Event.where(related_type: 'Parent', related_id: [parent1_id, parent2_id].compact)
  end

  def target_child?
    return unless group

    group.target_group?
  end

  def self.popi_parents
    parents.tagged_with('hors cible')
  end

  def self.popi_fathers_count
    popi_parents.fathers.count
  end

  def parent1_support_module
    ChildrenSupportModule.with_support_module.not_programmed.find_by(child_id: self.id,  parent_id: self.parent1_id)&.support_module
  end

  def support_module_not_programmed_name
    support_module = parent1_support_module
    return unless support_module

    support_module.name
  end

  def support_module_not_programmed_ages
    support_module = parent1_support_module
    return unless support_module

    support_module.decorate.display_age_ranges.gsub('/', '_')
  end

  def book_to_distribute_title
    support_module = parent1_support_module
    return unless support_module

    support_module.book_title
  end

  # ---------------------------------------------------------------------------
  # support
  # ---------------------------------------------------------------------------

  def create_support!(child_support_attributes = {})
    return if child_support

    if true_siblings.with_support.any?
      self.child_support_id = true_siblings.with_support.first.child_support.id
      save(validate: false)
    else
      # 1- create support
      child_support = ChildSupport.create!(child_support_attributes)

      # 2- use it on current child
      self.child_support_id = child_support.id
      save(validate: false)

      # 3- also update all strict siblings
      # nb: we do this one by one to trigger paper_trail
      true_siblings.without_support.each do |child|
        child.child_support_id = child_support.id
        child.save(validate: false)
      end
    end
  end

  def update_support
    return unless saved_change_to_parent1_id? || saved_change_to_parent2_id?
    return if true_siblings.with_support.empty?

    siblings_child_support = true_siblings.with_support.first.child_support
    return if child_support.nil?

    old_child_support = child_support
    siblings_child_support.copy_fields(child_support)
    siblings_child_support.save
    self.child_support_id = siblings_child_support.id
    save(validate: false)
    old_child_support.destroy if old_child_support.children.empty?
  end

  def add_to_group
    return unless group.nil?

    return unless group_status == 'waiting'

    Child::AddToGroupService.new(id, at_sign_up: true).call
  end

  def main_sibling
    return unless child_support

    child_support.current_child
  end

  def self.group_active
    where(group: Group.group_active)
  end

  def self.group_ended
    where(group: Group.group_ended)
  end

  def self.group_next
    where(group: Group.group_next)
  end

  # --------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  ransacker :child_group_status, formatter: proc { |values|
    values = Array(values)
    ids = []
    ids += group_active.pluck(:id) if values.include?('active')
    ids += group_ended.pluck(:id) if values.include?('ended')
    ids += group_next.pluck(:id) if values.include?('next')
    ids.uniq.presence
  } do |child|
    child.table[:id]
  end

  def self.ransackable_scopes(auth_object = nil)
    super + %i[months_equals months_gteq months_lt postal_code_contains postal_code_ends_with postal_code_equals postal_code_starts_with source_details_matches_any book_delivery_location]
  end

  def siblings_on_same_group
    return unless group_id

    siblings.where(group_id: group_id)
  end

  def have_siblings_on_same_group?
    return false unless siblings_on_same_group

    siblings_on_same_group.count > 1
  end

  def current_child?
    self == child_support&.current_child
  end

  def next_unprogrammed_children_support_module
    children_support_modules.where.not(support_module: nil).find_by(is_programmed: false)
  end

  def name_and_birthdate
    { first_name: first_name.parameterize, last_name: last_name.parameterize, birthdate: birthdate }
  end

  def duration_in_months(started_at, ended_at = Time.zone.now)
    return unless started_at && ended_at && ended_at >= started_at

    diff = ended_at.month + (ended_at.year * 12) - (started_at.month + (started_at.year * 12))
    if ended_at.day < started_at.day
      diff - 1
    else
      diff
    end
  end

  private

  def no_duplicate
    self.class.where('unaccent(first_name) ILIKE unaccent(?)', first_name).where(birthdate: birthdate).find_each do |child|
      errors.add(:base, :invalid, message: "L'enfant est déjà enregistré") if parent1.duplicate_of?(child.parent1) || parent1.duplicate_of?(child.parent2) || parent2&.duplicate_of?(child.parent1) || parent2&.duplicate_of?(child.parent2)
    end
  end

  def different_phone_number
    return unless parent2&.phone_number

    return unless parent1.phone_number == parent2.phone_number

    errors.add(:base, :invalid,
               message: "Nous avons besoin des coordonnées d'au moins un parent. Si l'autre parent ne souhaite pas recevoir les messages, merci de ne pas l'inscrire car nous n'avons pas besoin de son nom.")
  end

  def valid_group_status
    errors.add(:base, :invalid, message: "L'enfant ne peut pas être en attente en étant dans une cohorte") if group_id && group_status == 'waiting'
    errors.add(:base, :invalid, message: "L'enfant doit être dans une cohorte") if group_id.nil? && group_status.in?(%w[active paused stopped])
  end

  def remove_group
    return unless group_id

    self.group_id = nil
    save(validate: false)
  end

  def clean_child_support
    return if child_support.children.size == 1

    child_support.children.find_each do |child|
      next if child == self

      return if child.group_status.in?(%w[waiting active])
    end

    child_support.copy_fields(child_support)
    child_support.clean_fields
    child_support.save!
  end
end
