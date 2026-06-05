# == Schema Information
#
# Table name: call_session_date_overrides
#
#  id            :bigint           not null, primary key
#  call_session  :integer          not null
#  end_date      :date             not null
#  start_date    :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :bigint           not null
#  group_id      :bigint           not null
#
# Indexes
#
#  index_call_session_date_overrides_on_admin_user_id  (admin_user_id)
#  index_call_session_date_overrides_on_group_id       (group_id)
#  index_call_session_date_overrides_on_trio           (admin_user_id,group_id,call_session) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (group_id => groups.id)
#
class CallSessionDateOverride < ApplicationRecord

  CALL_SESSIONS = [0, 1, 2, 3].freeze

  belongs_to :admin_user
  belongs_to :group

  validates :call_session,
            presence: true,
            inclusion: { in: CALL_SESSIONS },
            uniqueness: { scope: %i[admin_user_id group_id] }
  validates :start_date, :end_date, presence: true
  validate :start_date_before_or_equal_end_date
  validate :dates_within_group_call_session

  private

  def start_date_before_or_equal_end_date
    return if start_date.blank? || end_date.blank?

    errors.add(:base, :invalid, message: 'La date de début doit être antérieure ou égale à la date de fin') if start_date > end_date
  end

  def dates_within_group_call_session
    return if group.blank? || call_session.blank? || !CALL_SESSIONS.include?(call_session)

    group_start = group.send(:"call#{call_session}_start_date")
    group_end = group.send(:"call#{call_session}_end_date")

    if start_date.present? && group_start.present? && start_date < group_start
      errors.add(:base, :invalid, message: "La date de début doit être ultérieure au #{I18n.l(group_start)}")
    end

    if end_date.present? && group_end.present? && end_date > group_end
      errors.add(:base, :invalid, message: "La date de fin doit être antérieure au #{I18n.l(group_end)}")
    end
  end
end
