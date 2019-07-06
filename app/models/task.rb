class Task < ApplicationRecord

  belongs_to :reporter, class_name: :AdminUser, optional: true
  belongs_to :assignee, class_name: :AdminUser, optional: true
  belongs_to :related, polymorphic: true, optional: true

  validates :title, presence: true

  scope :todo, -> { where(done_at: nil) }
  scope :done, -> { where.not(done_at: nil) }
  scope :relating, ->(model) { where(related: model) }

  # ---------------------------------------------------------------------------
  # DONE
  # ---------------------------------------------------------------------------

  def is_done
    !done_at.nil?
  end
  alias :is_done? :is_done

  def is_done=(v)
    if %w(true t 1).include?((v || '').to_s.downcase)
      self.done_at = Time.now
    else
      self.done_at = nil
    end
  end

  # ---------------------------------------------------------------------------
  # global search
  # ---------------------------------------------------------------------------

  include PgSearch
  multisearchable against: %i(title description)

end
