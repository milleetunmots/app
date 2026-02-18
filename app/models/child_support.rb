# == Schema Information
#
# Table name: child_supports
#
#  id                                         :bigint           not null, primary key
#  address_suspected_invalid_at               :datetime
#  already_working_with                       :boolean
#  availability                               :string
#  book_not_received                          :string
#  books_quantity                             :string
#  calendly_booking_url                       :string
#  call0_attempt                              :string
#  call0_duration                             :integer
#  call0_goal_sent                            :string
#  call0_goals                                :text
#  call0_goals_sms                            :text
#  call0_language_awareness                   :string
#  call0_language_development                 :text
#  call0_notes                                :text
#  call0_parent_actions                       :text
#  call0_parent_progress                      :string
#  call0_reading_frequency                    :string
#  call0_review                               :string
#  call0_sendings_benefits                    :string
#  call0_sendings_benefits_details            :text
#  call0_status                               :string
#  call0_status_details                       :text
#  call0_talk_needed                          :boolean          default(FALSE), not null
#  call0_technical_information                :text
#  call0_tv_frequency                         :string
#  call0_why_talk_needed                      :text
#  call1_attempt                              :string
#  call1_avoid_disengagement_date             :datetime
#  call1_avoid_disengagement_details          :text
#  call1_duration                             :integer
#  call1_family_progress                      :string
#  call1_goals                                :text
#  call1_goals_sms                            :text
#  call1_goals_tracking                       :text
#  call1_language_awareness                   :string
#  call1_language_development                 :text
#  call1_notes                                :text
#  call1_parent_actions                       :text
#  call1_parent_progress                      :string
#  call1_previous_goals_follow_up             :string
#  call1_reading_frequency                    :string
#  call1_review                               :string
#  call1_sendings_benefits                    :string
#  call1_sendings_benefits_details            :text
#  call1_status                               :string
#  call1_status_details                       :text
#  call1_talk_needed                          :boolean          default(FALSE), not null
#  call1_technical_information                :text
#  call1_tv_frequency                         :string
#  call1_why_talk_needed                      :text
#  call2_attempt                              :string
#  call2_avoid_disengagement_date             :datetime
#  call2_avoid_disengagement_details          :text
#  call2_duration                             :integer
#  call2_family_progress                      :string
#  call2_goals                                :text
#  call2_goals_sms                            :text
#  call2_goals_tracking                       :text
#  call2_language_awareness                   :string
#  call2_language_development                 :text
#  call2_notes                                :text
#  call2_parent_actions                       :text
#  call2_parent_progress                      :string
#  call2_previous_goals_follow_up             :string
#  call2_reading_frequency                    :string
#  call2_review                               :string
#  call2_sendings_benefits                    :string
#  call2_sendings_benefits_details            :text
#  call2_status                               :string
#  call2_status_details                       :text
#  call2_talk_needed                          :boolean          default(FALSE), not null
#  call2_technical_information                :text
#  call2_tv_frequency                         :string
#  call2_why_talk_needed                      :text
#  call3_attempt                              :string
#  call3_avoid_disengagement_date             :datetime
#  call3_avoid_disengagement_details          :text
#  call3_duration                             :integer
#  call3_goals                                :text
#  call3_goals_sms                            :text
#  call3_goals_tracking                       :text
#  call3_language_awareness                   :string
#  call3_language_development                 :text
#  call3_notes                                :text
#  call3_parent_actions                       :text
#  call3_parent_progress                      :string
#  call3_previous_goals_follow_up             :string
#  call3_reading_frequency                    :string
#  call3_review                               :string
#  call3_sendings_benefits                    :string
#  call3_sendings_benefits_details            :text
#  call3_status                               :string
#  call3_status_details                       :text
#  call3_talk_needed                          :boolean          default(FALSE), not null
#  call3_technical_information                :text
#  call3_tv_frequency                         :string
#  call3_why_talk_needed                      :text
#  call_infos                                 :string
#  child_count                                :integer
#  discarded_at                               :datetime
#  family_support_should_be_stopped           :string
#  has_important_information_parental_consent :boolean          default(FALSE), not null
#  important_information                      :text
#  instagram_follower                         :string
#  instagram_user                             :string
#  is_bilingual                               :string           default("2_no_information")
#  most_present_parent                        :string
#  notes                                      :text
#  other_phone_number                         :string
#  parent1_available_support_module_list      :string           is an Array
#  parent2_available_support_module_list      :string           is an Array
#  parent_mid_term_rate                       :integer
#  parent_mid_term_reaction                   :string
#  parental_contexts                          :string           is an Array
#  restart_support_date                       :datetime
#  restart_support_details                    :text
#  second_language                            :string
#  should_be_read                             :boolean
#  stop_support_date                          :datetime
#  stop_support_details                       :text
#  stop_support_reason                        :string
#  suggested_videos_counter                   :jsonb            is an Array
#  to_call                                    :boolean
#  will_stay_in_group                         :boolean          default(FALSE), not null
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  module2_chosen_by_parents_id               :bigint
#  module3_chosen_by_parents_id               :bigint
#  module4_chosen_by_parents_id               :bigint
#  module5_chosen_by_parents_id               :bigint
#  module6_chosen_by_parents_id               :bigint
#  restart_support_caller_id                  :bigint
#  stop_support_caller_id                     :bigint
#  supporter_id                               :bigint
#
# Indexes
#
#  index_child_supports_on_book_not_received                      (book_not_received)
#  index_child_supports_on_call0_parent_progress                  (call0_parent_progress)
#  index_child_supports_on_call0_reading_frequency                (call0_reading_frequency)
#  index_child_supports_on_call0_tv_frequency                     (call0_tv_frequency)
#  index_child_supports_on_call1_parent_progress                  (call1_parent_progress)
#  index_child_supports_on_call1_reading_frequency                (call1_reading_frequency)
#  index_child_supports_on_call1_tv_frequency                     (call1_tv_frequency)
#  index_child_supports_on_call2_language_awareness               (call2_language_awareness)
#  index_child_supports_on_call2_parent_progress                  (call2_parent_progress)
#  index_child_supports_on_call3_language_awareness               (call3_language_awareness)
#  index_child_supports_on_call3_parent_progress                  (call3_parent_progress)
#  index_child_supports_on_discarded_at                           (discarded_at)
#  index_child_supports_on_module2_chosen_by_parents_id           (module2_chosen_by_parents_id)
#  index_child_supports_on_module3_chosen_by_parents_id           (module3_chosen_by_parents_id)
#  index_child_supports_on_module4_chosen_by_parents_id           (module4_chosen_by_parents_id)
#  index_child_supports_on_module5_chosen_by_parents_id           (module5_chosen_by_parents_id)
#  index_child_supports_on_module6_chosen_by_parents_id           (module6_chosen_by_parents_id)
#  index_child_supports_on_parent1_available_support_module_list  (parent1_available_support_module_list) USING gin
#  index_child_supports_on_parent2_available_support_module_list  (parent2_available_support_module_list) USING gin
#  index_child_supports_on_restart_support_caller_id              (restart_support_caller_id)
#  index_child_supports_on_should_be_read                         (should_be_read)
#  index_child_supports_on_stop_support_caller_id                 (stop_support_caller_id)
#  index_child_supports_on_supporter_id                           (supporter_id)
#
# Foreign Keys
#
#  fk_rails_...  (module2_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module3_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module4_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module5_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module6_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (restart_support_caller_id => admin_users.id)
#  fk_rails_...  (stop_support_caller_id => admin_users.id)
#  fk_rails_...  (supporter_id => admin_users.id)
#

class ChildSupport < ApplicationRecord

  include Discard::Model
  include TagsSharedConcern

  LANGUAGE_AWARENESS = %w[1_none 2_awareness].freeze
  PARENT_PROGRESS = %w[1_low 2_medium 3_high 4_excellent].freeze
  READING_FREQUENCY = %w[1_rarely 2_weekly 3_frequently 4_daily].freeze
  TV_FREQUENCY = %w[1_never 2_weekly 3_frequently 4_daily].freeze
  SENDINGS_BENEFITS = %w[1_none 2_far 3_remind 4_frequent 5_frequent_helps].freeze
  BOOKS_QUANTITY = %w[1_none 2_three_or_less 3_between_four_and_ten 4_more_than_ten].freeze
  BOOK_NOT_RECEIVED = %w[1_first_book 2_second_book 3_third_book 4_fourth_book 5_fifth_book 6_sixth_book 7_seventh_book].freeze
  CALL_STATUS = %w[1_ok 2_ko 3_unassigned_number 4_dont_call 5_unfinished].freeze
  FAMILY_PROGRESS = %w[1_yes 2_no 3_no_information].freeze
  GOALS_FOLLOW_UP = %w[1_succeed 2_tried 3_no_tried 4_no_goal 5_not_enough_information].freeze
  IS_BILINGUAL_OPTIONS = %w[0_yes 1_no 2_no_information].freeze
  INSTAGRAM_INFORMATION_OPTIONS = %w[0_yes 1_no 2_no_information].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :supporter, class_name: :AdminUser, optional: true
  belongs_to :module2_chosen_by_parents, class_name: :SupportModule, optional: true
  belongs_to :module3_chosen_by_parents, class_name: :SupportModule, optional: true
  belongs_to :module4_chosen_by_parents, class_name: :SupportModule, optional: true
  belongs_to :module5_chosen_by_parents, class_name: :SupportModule, optional: true
  belongs_to :module6_chosen_by_parents, class_name: :SupportModule, optional: true
  has_many :children, dependent: :nullify
  has_many :children_support_modules, through: :children
  has_many :scheduled_calls, dependent: :nullify
  has_one :current_child, -> { order(Arel.sql("CASE WHEN group_status = 'active' THEN 0 ELSE 1 END, birthdate DESC")) }, class_name: :Child
  has_one :parent1, through: :current_child
  has_one :parent2, through: :current_child

  accepts_nested_attributes_for :current_child
  accepts_nested_attributes_for :children_support_modules

  # getter to make select work in form
  attr_accessor :call0_resources_alternative_scripts, :call1_resources_alternative_scripts, :call2_resources_alternative_scripts, :call3_resources_alternative_scripts

  after_save do
    if saved_change_to_parent1_available_support_module_list?
      ChildrenSupportModule.where(child: current_child, parent: parent1, is_programmed: false).find_each do |csm|
        csm.update!(available_support_module_list: parent1_available_support_module_list)
      end
    end

    if saved_change_to_parent2_available_support_module_list?
      ChildrenSupportModule.where(child: current_child, parent: parent2, is_programmed: false).find_each do |csm|
        csm.update!(available_support_module_list: parent2_available_support_module_list)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  (0..3).each do |call_idx|
    validates "call#{call_idx}_status", inclusion: { in: CALL_STATUS, allow_blank: true }, on: :create
    validates "call#{call_idx}_language_awareness", inclusion: { in: LANGUAGE_AWARENESS, allow_blank: true }
    validates "call#{call_idx}_parent_progress", inclusion: { in: PARENT_PROGRESS, allow_blank: true }
    validates "call#{call_idx}_sendings_benefits", inclusion: { in: SENDINGS_BENEFITS, allow_blank: true }
  end

  validates :books_quantity, inclusion: { in: BOOKS_QUANTITY, allow_blank: true }
  validates :is_bilingual, inclusion: { in: IS_BILINGUAL_OPTIONS }
  validates :instagram_follower, inclusion: { in: INSTAGRAM_INFORMATION_OPTIONS, allow_blank: true }
  validates :instagram_user, inclusion: { in: INSTAGRAM_INFORMATION_OPTIONS, allow_blank: true }
  validates :has_important_information_parental_consent, acceptance: true, if: -> { important_information.present? && new_record? }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :with_a_child_in_active_group, -> { joins(children: :group).where(children: { group_status: 'active' }).distinct }
  scope :supported_by, ->(supporter) { with_a_child_in_active_group.joins(:children).where(children: { group_status: 'active' }).where(supporter: supporter) }
  scope :all_supported_by, ->(supporter_id) { joins(:supporter).where(supporter: { id: supporter_id }) }
  scope :active_supported_by, ->(supporter_id) { all_supported_by(supporter_id).joins(:children).where(children: { group_status: 'active' }) }
  scope :not_active_supported_by, ->(supporter_id) { all_supported_by(supporter_id).joins(:children).where.not(children: { group_status: 'active' }) }
  scope :in_group, ->(group_id) { joins(children: :group).where(children: { group_id: group_id }) }
  scope :without_supporter, -> { where(supporter_id: nil) }
  scope :call_2_4, -> {
    where('call1_status ILIKE ? AND call3_status = ?', 'ko', '')
      .or(where('call3_status ILIKE ?', 'ko'))
      .or(where('call1_parent_progress = ? AND call3_parent_progress = ?', '1_low', ''))
      .or(where('call1_parent_progress = ? AND call3_parent_progress = ?', '2_medium', ''))
      .or(where(call3_parent_progress: '1_low'))
      .or(where(call3_parent_progress: '2_medium'))
      .or(where(to_call: true))
      .with_a_child_in_active_group
  }
  scope :with_children, -> { joins(:children) }
  scope :multiple_children, -> { joins(:children).group('child_supports.id').having('count(children.id) > 1') }
  scope :one_child, -> { joins(:children).group('child_supports.id').having('count(children.id) = 1') }
  scope :paused_or_stopped, -> {
    where(
      'NOT EXISTS (
        SELECT 1
        FROM children
        WHERE children.child_support_id = child_supports.id
        AND children.group_status IN (?, ?)
      )',
      'waiting', 'active'
    )
  }
  scope :with_unassigned_number, -> {
    where('call0_status ILIKE ?', 'Numéro erroné')
      .or(where('call1_status ILIKE ?', 'Numéro erroné'))
      .or(where('call2_status ILIKE ?', 'Numéro erroné'))
      .or(where('call3_status ILIKE ?', 'Numéro erroné'))
  }
  scope :with_kept_children, -> {
    where(
      "EXISTS (
        SELECT 1
        FROM children
        WHERE children.child_support_id = child_supports.id
        AND children.discarded_at IS NULL
      )"
    )
  }
  scope :without_supporter_in_active_programmed_group, -> {
    joins(children: :group)
      .where(
        children: { group_status: 'active', discarded_at: nil },
        groups: { is_programmed: true, discarded_at: nil, type_of_support: 'with_calls' },
        supporter_id: nil
      )
      .where('groups.ended_at IS NULL OR groups.ended_at > ?', Time.zone.today)
      .distinct
  }
  scope :with_child_in_group_ended_between, lambda { |start_date, end_date|
    joins(children: :group).where(groups: { ended_at: start_date..end_date }).distinct
  }
  scope :without_scheduled_calls, -> {
    left_joins(:scheduled_calls).where(scheduled_calls: { id: nil })
  }
  scope :with_valid_supporter_for_calendly, -> {
    with_a_child_in_active_group
      .joins(:supporter)
      .where(supporter: { can_send_automatic_sms: true })
      .where.not(supporter: { aircall_number_id: nil })
      .where.not(supporter: { calendly_user_uri: nil })
  }

  class << self

    (0..3).each do |call_idx|
      define_method("call#{call_idx}_parent_progress_present") do |bool|
        if bool
          where("call#{call_idx}_parent_progress" => PARENT_PROGRESS)
        else
          where.not("call#{call_idx}_parent_progress" => PARENT_PROGRESS)
        end
      end

      define_method("call#{call_idx}_sendings_benefits_present") do |bool|
        if bool
          where("call#{call_idx}_sendings_benefits" => SENDINGS_BENEFITS)
        else
          where.not("call#{call_idx}_sendings_benefits" => SENDINGS_BENEFITS)
        end
      end
    end
  end

  def self.groups_in(*v)
    where(id: Child.where(group_id: v).select('DISTINCT child_support_id'))
  end

  def self.group_id_in(*v)
    where(id: Child.group_id_in(v).select('DISTINCT child_support_id'))
  end

  def self.active_group_id_in(*v)
    where(id: Child.active_group_id_in(v).select('DISTINCT child_support_id'))
  end

  def self.source_in(*v)
    where(id: Child.source_id_in(v).select('DISTINCT child_support_id'))
  end

  def self.source_channel_in(*v)
    where(id: Child.source_channel_in(v).select('DISTINCT child_support_id'))
  end

  def self.source_details_matches_any(*v)
    where(id: Child.source_details_matches_any(v).select('DISTINCT child_support_id'))
  end

  def self.postal_code_contains(v)
    where(id: Child.postal_code_contains(v).select('DISTINCT child_support_id'))
  end

  def self.postal_code_ends_with(v)
    where(id: Child.postal_code_ends_with(v).select('DISTINCT child_support_id'))
  end

  def self.postal_code_equals(v)
    where(id: Child.postal_code_equals(v).select('DISTINCT child_support_id'))
  end

  def self.postal_code_starts_with(v)
    where(id: Child.postal_code_starts_with(v).select('DISTINCT child_support_id'))
  end

  def self.months_gteq(x)
    where(id: Child.months_gteq(x).select('DISTINCT child_support_id'))
  end

  def self.months_lt(x)
    where(id: Child.months_lt(x).select('DISTINCT child_support_id'))
  end

  def self.months_equals(x)
    where(id: Child.months_equals(x).select('DISTINCT child_support_id'))
  end

  def self.months_between(x, y)
    where(id: Child.months_between(x, y).select('DISTINCT child_support_id'))
  end

  scope :with_book_not_received, -> { where.not(book_not_received: [nil, '']) }

  def self.group_active
    where(id: Child.group_active.select('DISTINCT child_support_id'))
  end

  def self.group_ended
    where(id: Child.group_ended.select('DISTINCT child_support_id'))
  end

  def self.group_next
    where(id: Child.group_next.select('DISTINCT child_support_id'))
  end

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  ransacker :children_group_status, formatter: proc { |values|
    values = Array(values)
    ids = []
    ids += group_active.pluck(:id) if values.include?('active')
    ids += group_ended.pluck(:id) if values.include?('ended')
    ids += group_next.pluck(:id) if values.include?('next')
    ids.uniq.presence
  } do |child_support|
    child_support.table[:id]
  end

  ransacker :stopped_by_supporter, formatter: proc { |values|
    values = Array(values)
    ids = []
    ids += where.not(stop_support_date: nil).pluck(:id) if values.include?('stopped')
    ids += where(stop_support_date: nil).pluck(:id) if values.include?('ongoing')
    ids.uniq.presence
  } do |child_support|
    child_support.table[:id]
  end

  def self.ransackable_scopes(auth_object = nil)
    super + %i[
      groups_in postal_code_contains postal_code_ends_with postal_code_equals postal_code_starts_with source_in source_channel_in
      source_details_matches_any group_id_in active_group_id_in with_child_in_group_ended_between
      months_gteq months_lt months_equals months_between
    ]
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def self.create_call_status_ransacker(call)
    ransacker :"#{call}_status_filter", formatter: proc { |value|
      results = ChildSupport.where("#{call}_status": value).map(&:id) if value.in?(ChildSupport::CALL_STATUS.map { |v| ChildSupport.human_attribute_name("call_status.#{v}") })
      results = ChildSupport.where("#{call}_status": [nil, '']).map(&:id) if value == 'nil'
      results
    } do |parent|
      parent.table[:id]
    end
  end

  (0..3).each do |call_idx|
    define_method("call#{call_idx}_parent_progress_index") do
      (send("call#{call_idx}_parent_progress") || '').split('_').first&.to_i
    end

    define_method("call#{call_idx}_previous_call_goals") do
      call_idx.zero? ? '' : previous_call_goals(call_idx).strip
    end

    create_call_status_ransacker("call#{call_idx}")
  end

  def self.call_attributes
    new.attributes.keys.select { |a| a.starts_with?('call') }
  rescue ArgumentError
    []
  end

  def other_children
    all_parent_ids = children.pluck(:parent1_id, :parent2_id).join(',').split(',').uniq
    Child.parent_id_in(all_parent_ids).where.not(child_support: self)
  end

  def has_other_family_child_supports?
    other_children.with_support.any?
  end

  def other_family_child_supports
    other_children.with_support.map(&:child_support).uniq
  end

  def scheduled_call_sessions(index)
    scheduled_calls.where(call_session: index.to_i)
  end

  # ---------------------------------------------------------------------------
  # methods
  # ---------------------------------------------------------------------------

  delegate :address,
           :city_name,
           :group_status,
           :group_enable_calls_recording,
           :letterbox_name,
           :parent_events,
           :parent1_first_name,
           :parent1_gender,
           :parent1_is_ambassador,
           :parent1_is_ambassador?,
           :parent1_present_on_whatsapp,
           :parent1_present_on_whatsapp?,
           :parent1_follow_us_on_whatsapp,
           :parent1_follow_us_on_whatsapp?,
           :parent1_last_name,
           :parent1_phone_number_national,
           :parent1_book_delivery_location,
           :parent2_first_name,
           :parent2_gender,
           :parent2_is_ambassador,
           :parent2_is_ambassador?,
           :parent2_present_on_whatsapp,
           :parent2_present_on_whatsapp?,
           :parent2_follow_us_on_whatsapp,
           :parent2_follow_us_on_whatsapp?,
           :parent2_last_name,
           :parent2_phone_number_national,
           :postal_code,
           :should_contact_parent1,
           :should_contact_parent1?,
           :should_contact_parent2,
           :should_contact_parent2?,
           to: :current_child,
           allow_nil: true

  delegate :name,
           to: :supporter,
           prefix: true,
           allow_nil: true

  def previous_call_goals(index)
    (0..(index - 1)).reverse_each do |i|
      previous_call_goals = "#{send("call#{i}_goals_sms".to_sym)}\n#{send("call#{i}_goals")}"
      return previous_call_goals if previous_call_goals != "\n"
    end
    ''
  end

  def book_not_received
    super&.split(';')
  end

  def book_not_received=(val)
    super((val || []).reject(&:blank?).join(';'))
  end

  def copy_fields(child_support)
    self.notes ||= ''
    self.notes << (('-' * 100) + "\n")
    self.notes << "\n#{I18n.l(Time.zone.now)} - Sauvegarde des informations de la fiche de suivi\n\n"
    self.notes << "Informations générales\n\n"
    child_support.attributes.slice(
      'is_bilingual',
      'second_language',
      'important_information',
      'availability',
      'call_infos',
      'book_not_received',
      'tag_list'
    ).each do |attribute, value|
      self.notes << "#{I18n.t("activerecord.attributes.child_support.#{attribute}")} : #{value}\n"
    end

    self.notes << "\nInformations de chaque appel\n"
    self.notes << '='*22 + "\n"
    (0..3).each do |call_idx|
      self.notes << "\n--------Appel #{call_idx}--------\n"

      call_attributes = [
        "call#{call_idx}_status",
        "call#{call_idx}_talk_needed",
        "call#{call_idx}_why_talk_needed",
        "call#{call_idx}_status_details",
        "call#{call_idx}_duration",
        "call#{call_idx}_technical_information",
        "call#{call_idx}_parent_actions",
        "call#{call_idx}_parent_progress",
        "call#{call_idx}_sendings_benefits",
        "call#{call_idx}_sendings_benefits_details",
        "call#{call_idx}_language_development",
        "call#{call_idx}_reading_frequency",
        "call#{call_idx}_goals",
        "call#{call_idx}_tv_frequency",
        "call#{call_idx}_notes"
      ]
      call_attributes += %w[call2_family_progress call2_previous_goals_follow_up] if call_idx == 2
      call_attributes += ['books_quantity'] if call_idx == 1

      call_attributes.each do |call_attr|
        self.notes << "#{I18n.t("activerecord.attributes.child_support.#{call_attr}")} : #{child_support.send(call_attr)}\n"
      end
    end
    self.notes << (('=' * 22) + "\n")
  end

  def clean_fields
    self.supporter_id = nil
    self.is_bilingual = '2_no_information'
    attributes.slice(
      'second_language',
      'important_information',
      'availability',
      'call_infos',
      'book_not_received',
      'tag_list'
    ).each_key do |attribute|
      self[attribute.to_sym] = nil
    end

    4.times.each do |call_idx|
      call_attributes = [
        "call#{call_idx}_status",
        "call#{call_idx}_status_details",
        "call#{call_idx}_duration",
        "call#{call_idx}_why_talk_needed",
        "call#{call_idx}_talk_needed",
        "call#{call_idx}_technical_information",
        "call#{call_idx}_parent_actions",
        "call#{call_idx}_parent_progress",
        "call#{call_idx}_sendings_benefits",
        "call#{call_idx}_sendings_benefits_details",
        "call#{call_idx}_language_development",
        "call#{call_idx}_reading_frequency",
        "call#{call_idx}_goals",
        "call#{call_idx}_notes",
        "call#{call_idx}_previous_goals_follow_up",
        "call#{call_idx}_tv_frequency",
        "call#{call_idx}_review"
      ]
      call_attributes += %w[call2_family_progress] if call_idx == 2
      call_attributes -= %w[call0_previous_goals_follow_up] if call_idx == 0
      call_attributes += ['books_quantity'] if call_idx == 1

      call_attributes.each do |call_attr|
        # handle attributes that dont accept nil (ie. booleans)
        if self.class.respond_to?(:attribute_defaults)
          default_value = self.class.attribute_defaults[call_attr.to_s]
        else
          default_value = self.class.columns_hash[call_attr.to_s]&.default
        end
        self[call_attr.to_sym] = default_value
      end
    end
  end

  def current_call_session
    return 0 unless current_child

    group = current_child.group
    return 0 unless group&.started?

    date = Time.zone.now.to_date

    4.times.each do |call_idx|
      return call_idx if group.send("call#{call_idx}_start_date").present? && group.send("call#{call_idx}_end_date").present? && (group.send("call#{call_idx}_start_date")..group.send("call#{call_idx}_end_date")) === date
    end

    3.downto(0).find do |call_idx|
      return call_idx if send("call#{call_idx}_status").present?
    end
    0
  end

  def self.call_ok_or_unfinished_for(call_index)
    where("call#{call_index}_status IN (?, ?)", ChildSupport.human_attribute_name("call_status.1_ok"), ChildSupport.human_attribute_name("call_status.5_unfinished"))
  end

  def self.previous_calls_ok_or_unfinished_before(call_index)
    case call_index
    when 0
      all
    when 1
      call_ok_or_unfinished_for(0)
    when 2
      call_ok_or_unfinished_for(0).and(call_ok_or_unfinished_for(1))
    when 3
      call_ok_or_unfinished_for(0).and(call_ok_or_unfinished_for(1)).and(call_ok_or_unfinished_for(2))
    else
      none
    end
  end

  def self.call_not_ok_and_not_unfinished_for(call_index)
    where("call#{call_index}_status IN (?, ?, ?)",
          ChildSupport.human_attribute_name("call_status.2_ko"),
          ChildSupport.human_attribute_name("call_status.3_unassigned_number"),
          ChildSupport.human_attribute_name("call_status.4_dont_call"))
  end

  def self.at_least_one_call_not_ok_and_not_unfinished(call_index)
    case call_index
    when 0
      none
    when 1
      call_not_ok_and_not_unfinished_for(0)
    when 2
      call_not_ok_and_not_unfinished_for(0).or(call_not_ok_and_not_unfinished_for(1))
    when 3
      call_not_ok_and_not_unfinished_for(0).or(call_not_ok_and_not_unfinished_for(1)).or(call_not_ok_and_not_unfinished_for(2))
    else
      none
    end
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable
end
