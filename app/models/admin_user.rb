# == Schema Information
#
# Table name: admin_users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
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

  ROLES = %w[super_admin team_member caller].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :reported_tasks, class_name: "Task", foreign_key: "reporter_id", dependent: :nullify
  has_many :assigned_tasks, class_name: "Task", foreign_key: "assignee_id", dependent: :nullify

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false}
  validates :user_role, inclusion: {in: ROLES}

  def admin?
    user_role == "super_admin"
  end

  def team_member?
    user_role == "team_member"
  end

  def caller?
    user_role == "caller"
  end
end
