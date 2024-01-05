# == Schema Information
#
# Table name: tasks
#
#  id           :bigint           not null, primary key
#  description  :text
#  discarded_at :datetime
#  done_at      :date
#  due_date     :date
#  related_type :string
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  assignee_id  :bigint
#  related_id   :bigint
#  reporter_id  :bigint
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
#
# Foreign Keys
#
#  fk_rails_...  (assignee_id => admin_users.id)
#  fk_rails_...  (reporter_id => admin_users.id)
#

class Task < ApplicationRecord

  include Discard::Model

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :reporter, class_name: :AdminUser, optional: true
  belongs_to :assignee, class_name: :AdminUser, optional: true
  belongs_to :related, polymorphic: true, optional: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :title, presence: true

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :todo, -> { where(done_at: nil) }
  scope :done, -> { where.not(done_at: nil) }
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

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i[title description]

end
