# == Schema Information
#
# Table name: external_users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  password_digest        :string
#  remember_created_at    :datetime
#  remember_token         :string
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
  include Clearance::User

  attr_accessor :skip_password_validation

  belongs_to :source

  enum role: { pmi_user: 'pmi_user', pmi_admin: 'pmi_admin' }

  validates :role, inclusion: { in: roles.keys }
  validates :password, presence: true, unless: :skip_password_validation?
  
  def skip_password_validation?
    skip_password_validation || persisted?
  end
end
