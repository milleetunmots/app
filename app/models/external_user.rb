# == Schema Information
#
# Table name: external_users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("pmi_user"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  source_id              :bigint
#
# Indexes
#
#  index_external_users_on_email                 (email) UNIQUE
#  index_external_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_external_users_on_source_id             (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (source_id => sources.id)
#
class ExternalUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :source

  enum roles: { pmi_user: 'pmi_user', pmi_admin: 'pmi_admin' }

  validates :role, inclusion: { in: roles.keys }
end
