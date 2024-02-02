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

  GENDERS = %w[m f].freeze
  REGISTRATION_SOURCES = %w[caf pmi friends therapist nursery doctor resubscribing other].freeze
  PMI_LIST = %w[orleans orleans_est montargis gien pithiviers olivet sarreguemines forbach trappes plaisir mantes_la_jolie_clemenceau mantes_la_jolie_leclerc
                gennevilliers_zucman_gabison gennevilliers_timsit asnieres_gennevilliers_sst2 villeneuve_la_garenne chanteloup sartrouville les_mureaux seine_st_denis vernouillet val_de_saone_dombes
                plaine_de_l_ain_cotiere bugey_pays_de_gex bresse_revermont].freeze
  GROUP_STATUS = %w[waiting active paused stopped disengaged].freeze
  TERRITORIES = %w[Loiret Yvelines Seine-Saint-Denis Paris Moselle].freeze
  LANDS = ['Paris 18 eme', 'Paris 20 eme', 'Plaisir', 'Trappes', 'Aulnay sous bois', 'Bondy', 'Orleans', 'Montargis', 'Pithiviers', 'Gien', 'Villeneuve-la-Garenne', 'Mantes La Jolie'].freeze

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

  accepts_nested_attributes_for :child_support
  accepts_nested_attributes_for :parent1
  accepts_nested_attributes_for :parent2

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
  validates :registration_source, presence: true, inclusion: { in: REGISTRATION_SOURCES }
  validates :registration_source_details, presence: true
  validates :security_code, presence: true
  validates :pmi_detail, inclusion: { in: PMI_LIST, allow_blank: true }
  validates :group_status, inclusion: { in: GROUP_STATUS }
  validate :no_duplicate, on: :create
  validate :different_phone_number, on: :create
  validate :valid_group_status

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  def initialize(attributes = {})
    super
    self.security_code = SecureRandom.hex(1)
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
  after_create :add_to_group
  after_update :update_support

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
  scope :with_ongoing_group, -> { joins(:group).merge(Group.started) }
  scope :potential_duplicates, -> {
    where("(unaccent(children.first_name), unaccent(children.last_name), children.birthdate) IN (SELECT unaccent(first_name), unaccent(last_name), birthdate FROM children GROUP BY unaccent(children.first_name), unaccent(children.last_name), children.birthdate HAVING COUNT(*) > 1)")
  }

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

  def self.without_parent_text_message_since(v)
    parent_id_not_in(
      Events::TextMessage.where(related_type: :Parent).where('occurred_at >= ?', v).pluck('DISTINCT related_id')
    )
  end

  def self.registration_source_details_matches_any(*v)
    where('registration_source_details ILIKE ?', v)
  end

  def self.by_lands(lands)
    postal_codes = []
    lands.each do |land|
      case land
      when 'Paris 18 eme'
        postal_codes += Parent::PARIS_18_EME_POSTAL_CODE
      when 'Paris 20 eme'
        postal_codes += Parent::PARIS_20_EME_POSTAL_CODE
      when 'Plaisir'
        postal_codes += Parent::PLAISIR_POSTAL_CODE
      when 'Trappes'
        postal_codes += Parent::TRAPPES_POSTAL_CODE
      when 'Aulnay sous bois'
        postal_codes += Parent::AULNAY_SOUS_BOIS_POSTAL_CODE
      when 'Orleans'
        postal_codes += Parent::ORELANS_POSTAL_CODE
      when 'Montargis'
        postal_codes += Parent::MONTARGIS_POSTAL_CODE
      when 'Gien'
        postal_codes += Parent::GIEN_POSTAL_CODE
      when 'Pithiviers'
        postal_codes += Parent::PITHIVIERS_POSTAL_CODE
      when 'Bondy'
        postal_codes += Parent::BONDY_POSTAL_CODE
      when 'Mantes La Jolie'
        postal_codes += Parent::MANTES_LA_JOLIE_POSTAL_CODE
      end
    end

    joins(:parent1).where(parents: { postal_code: postal_codes })
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

  def self.four_to_nine
    months_between(4, 10).where(group_status: 'active')
  end

  def self.ten_to_fifteen
    months_between(10, 16).where(group_status: 'active')
  end

  def self.sixteen_to_twenty_three
    months_between(16, 24).where(group_status: 'active')
  end

  def self.twenty_four_and_more
    months_gteq(24).where(group_status: 'active')
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
      ).downcase.gsub(/[\s-]+/, ' ').strip
      values[normalized_value] ||= []
      values[normalized_value] << value
    end

    # use first found value as map key and remove duplicates
    values.map do |_k, v|
      [v.first, v.uniq]
    end.to_h
  end

  # ---------------------------------------------------------------------------
  # methods
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
           :present_on_facebook,
           :present_on_facebook?,
           :present_on_whatsapp,
           :present_on_whatsapp?,
           :follow_us_on_facebook,
           :follow_us_on_facebook?,
           :follow_us_on_whatsapp,
           :follow_us_on_whatsapp?,
           to: :parent1,
           prefix: true

  delegate :is_ambassador,
           :is_ambassador?,
           :present_on_facebook,
           :present_on_facebook?,
           :present_on_whatsapp,
           :present_on_whatsapp?,
           :follow_us_on_facebook,
           :follow_us_on_facebook?,
           :follow_us_on_whatsapp,
           :follow_us_on_whatsapp?,
           to: :parent2,
           prefix: true,
           allow_nil: true

  delegate :name,
           to: :group,
           prefix: true,
           allow_nil: true

  delegate :id,
           to: :child_support,
           prefix: true,
           allow_nil: true

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
    old_child_support.destroy
    save(validate: false)
  end

  def add_to_group
    return unless group.nil?

    self.group = months > 4 ? Group.next_available_at(Time.zone.today) : Group.next_available_at(birthdate + 4.months)
    self.group_status = 'active' if group
    save(validate: false)
  end

  # --------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    super + %i[months_equals months_gteq months_lt postal_code_contains postal_code_ends_with postal_code_equals postal_code_starts_with active_group_id_in
               without_parent_text_message_since registration_source_details_matches_any]
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

  private

  def no_duplicate
    self.class.where('unaccent(first_name) ILIKE unaccent(?)', first_name).where(birthdate: birthdate).find_each do |child|
      if parent1.duplicate_of?(child.parent1) || parent1.duplicate_of?(child.parent2) || parent2&.duplicate_of?(child.parent1) || parent2&.duplicate_of?(child.parent2)
        errors.add(:base, :invalid, message: "L'enfant est déjà enregistré")
      end
    end
  end

  def different_phone_number
    return unless parent2&.phone_number

    if parent1.phone_number == parent2.phone_number
      errors.add(:base, :invalid,
                 message: "Nous avons besoin des coordonnées d'au moins un parent. Si l'autre parent ne souhaite pas recevoir les messages, merci de ne pas l'inscrire car nous n'avons pas besoin de son nom.")
    end
  end

  def valid_group_status
    errors.add(:base, :invalid, message: "L'enfant ne peut pas être en attente en étant dans une cohorte") if group_id && group_status == 'waiting'
    errors.add(:base, :invalid, message: "L'enfant doit être dans une cohorte") if group_id.nil? && group_status != 'waiting'
  end

  def duration_in_months(started_at, ended_at = Time.zone.now)
    return unless started_at && ended_at && ended_at > started_at

    diff = ended_at.month + (ended_at.year * 12) - (started_at.month + (started_at.year * 12))
    if ended_at.day < started_at.day
      diff - 1
    else
      diff
    end
  end
end
