# == Schema Information
#
# Table name: tasks
#
#  id            :bigint           not null, primary key
#  description   :text
#  discarded_at  :datetime
#  done_at       :date
#  due_date      :date
#  related_type  :string
#  status        :string
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assignee_id   :bigint
#  related_id    :bigint
#  reporter_id   :bigint
#  treated_by_id :bigint
#
# Indexes
#
#  index_tasks_on_assignee_id                  (assignee_id)
#  index_tasks_on_description                  (description)
#  index_tasks_on_discarded_at                 (discarded_at)
#  index_tasks_on_done_at                      (done_at)
#  index_tasks_on_due_date                     (due_date)
#  index_tasks_on_related_type_and_related_id  (related_type,related_id)
#  index_tasks_on_reporter_id                  (reporter_id)
#  index_tasks_on_title                        (title)
#  index_tasks_on_treated_by_id                (treated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignee_id => admin_users.id)
#  fk_rails_...  (reporter_id => admin_users.id)
#  fk_rails_...  (treated_by_id => admin_users.id)
#

class Task < ApplicationRecord

  TITLES_WITH_ASSIGNEE_EMAIL = {
    disable_one_twin_support: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    remove_duplicate_child: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    reunite_siblings_same_cohort: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    reactivate_sms_parent: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    group_siblings_same_record: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    add_sibling_to_record: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    clean_and_archive_record: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    write_custom_task: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    unsure_if_task_needed: ENV['OPERATION_PROJECT_MANAGER_EMAIL'],
    stop_non_consenting_family_support: ENV['COORDINATOR_EMAIL'],
    stop_problematic_family_support: ENV['COORDINATOR_EMAIL'],
    stop_non_french_speaking_family_support: ENV['COORDINATOR_EMAIL']
  }.freeze

  STATUS = %w[done in_progress].freeze

  include Discard::Model

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  before_create :translate_title

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :reporter, class_name: :AdminUser, optional: true
  belongs_to :assignee, class_name: :AdminUser, optional: true
  belongs_to :treated_by, class_name: :AdminUser, optional: true
  belongs_to :related, polymorphic: true, optional: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :title, presence: true
  validate :valid_treated_by

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :todo, -> { where(done_at: nil) }
  scope :done, -> { where.not(done_at: nil) }
  scope :caller_task, ->(model) { where(reporter: model) }
  scope :relating, ->(model) { where(related: model) }
  scope :assigned_to, ->(model) { where(assignee: model) }
  scope :not_assigned_to, ->(model) { where.not(assignee: model) }

  # ---------------------------------------------------------------------------
  # DONE
  # ---------------------------------------------------------------------------

  def is_done
    !done_at.nil?
  end
  alias_method :is_done?, :is_done

  def is_done=(v)
    self.done_at = if %w[true t 1].include?((v || '').to_s.downcase)
      Time.zone.now
    end
  end

  def new_related_to_child_support?
    id.nil? && related&.instance_of?(ChildSupport)
  end

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i[title description]

  private

  def translate_title
    return unless title.in?(Task::TITLES_WITH_ASSIGNEE_EMAIL.keys.map(&:to_s))

    self.title = Task.human_attribute_name("child_support_task_title.#{title}")
  end

  def valid_treated_by
    errors.add(:base, :invalid, message: "Vous n'avez pas l'autorisation de traiter les tâches") if treated_by.nil? && status == 'in_progress'
  end
end
