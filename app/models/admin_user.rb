# == Schema Information
#
# Table name: admin_users
#
#  id                     :bigint           not null, primary key
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
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class AdminUser < ApplicationRecord

  ROLES = %w[super_admin team_member logistics_team caller].freeze
  COMMON_PASSWORDS = %w[1001 mots password azerty 1234 motdepasse qwerty 12345 000 bonjour soleil abc 111].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :reported_tasks, class_name: "Task", foreign_key: "reporter_id", dependent: :nullify
  has_many :assigned_tasks, class_name: "Task", foreign_key: "assignee_id", dependent: :nullify
  has_many :workshops, foreign_key: 'animator_id', dependent: :nullify
  has_many :child_supports, foreign_key: 'supporter_id', inverse_of: :supporter, dependent: :nullify
  has_many :children, through: :child_supports

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :user_role, inclusion: { in: ROLES }
  validates :password, format: { with: REGEX_VALID_PASSWORD, message: INVALID_PASSWORD_MESSAGE }
  validate :common_password

  scope :all_logistics_team_members, -> { where(user_role: "logistics_team") }
  scope :callers, -> { where(user_role: "caller") }
  scope :supporters, -> { joins(:child_supports).distinct }
  scope :account_disabled, -> { where(is_disabled: true) }
  scope :account_not_disabled, -> { where(is_disabled: false) }

  def admin?
    user_role == "super_admin"
  end

  def team_member?
    user_role == "team_member"
  end

  def logistics_team?
    user_role == "logistics_team"
  end

  def caller?
    user_role == "caller"
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

  private

  def common_password
    found_common_password = COMMON_PASSWORDS.find { |common_password| password.downcase.include?(common_password) }
    return unless found_common_password

    errors.add(:password, "ne doit pas contenir ce mot trop commun : '#{found_common_password}'")
  end
end
