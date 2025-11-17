# == Schema Information
#
# Table name: admin_users
#
#  id                     :bigint           not null, primary key
#  aircall_phone_number   :string
#  can_export_data        :boolean          default(FALSE), not null
#  can_send_automatic_sms :boolean          default(TRUE), not null
#  can_treat_task         :boolean          default(FALSE), not null
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  is_disabled            :boolean          default(FALSE)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  user_role              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  aircall_number_id      :bigint
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class AdminUser < ApplicationRecord

  ROLES = %w[super_admin contributor reader caller animator].freeze
  COMMON_PASSWORDS = %w[1001 mots password azerty 1234 motdepasse qwerty 12345 000 bonjour soleil abc 111].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :reported_tasks, class_name: 'Task', foreign_key: 'reporter_id', dependent: :nullify
  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assignee_id', dependent: :nullify
  has_many :workshops, foreign_key: 'animator_id', dependent: :nullify
  has_many :child_supports, foreign_key: 'supporter_id', inverse_of: :supporter, dependent: :nullify
  has_many :children, through: :child_supports

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :user_role, inclusion: { in: ROLES }
  validates :password, format: { with: REGEX_VALID_PASSWORD, message: INVALID_PASSWORD_MESSAGE }, unless: -> { password.blank? }
  validate :common_password

  scope :callers, -> { where(user_role: 'caller') }
  scope :supporters, -> { joins(:child_supports).distinct }
  scope :account_disabled, -> { where(is_disabled: true) }
  scope :account_not_disabled, -> { where(is_disabled: false) }

  after_create :set_aircall_phone_number

  def admin?
    user_role == 'super_admin'
  end

  def contributor?
    user_role == 'contributor'
  end

  def reader?
    user_role == 'reader'
  end

  def caller?
    user_role == 'caller'
  end

  def animator?
    user_role == 'animator'
  end

  def supporter?
    child_supports.any?
  end

  def active_for_authentication?
    super and !self.is_disabled?
  end

  def inactive_message
    "Ce compte n'est pas activé."
  end

  def self.any_caller_or_animator_with_id?(id)
    exists?(id: id, user_role: ['caller', 'animator'])
  end

  def set_aircall_phone_number
    return if aircall_phone_number.present? && aircall_number_id.present?

    aircall_user_service = Aircall::RetrieveUserService.new.call
    if aircall_user_service.errors.any?
      Rollbar.error("Set phone_number error : #{aircall_user_service.errors}")
      return
    end

    aircall_user = aircall_user_service.users.find do |user|
      (I18n.transliterate(user['name'].downcase.squish) == I18n.transliterate(name.downcase.squish)) ||
        (I18n.transliterate(user['email'].downcase.squish) == I18n.transliterate(email.downcase.squish))
    end
    return unless aircall_user

    aircall_user_service = Aircall::RetrieveUserService.new(user_id: aircall_user['id']).call
    if aircall_user_service.errors.any?
      Rollbar.error("Set phone_number error for #{id} : #{aircall_user_service.errors}")
      return
    end

    aircall_user = aircall_user_service.users.first
    phone_number = aircall_user.try(:[], 'numbers')&.first.try(:[], 'digits')
    number_id = aircall_user.try(:[], 'numbers')&.first.try(:[], 'id')
    unless phone_number && number_id
      Rollbar.error("Set phone number error for #{id} : No digits")
      return
    end

    self.update(aircall_phone_number: Phonelib.parse(phone_number).e164, aircall_number_id: number_id)
  end

  private

  def common_password
    return unless password

    found_common_password = COMMON_PASSWORDS.find { |common_password| password.downcase.include?(common_password) }
    return unless found_common_password

    errors.add(:password, "ne doit pas contenir ce mot trop commun : '#{found_common_password}'")
  end
end
