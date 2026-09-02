# == Schema Information
#
# Table name: admin_users
#
#  id                         :bigint           not null, primary key
#  aircall_phone_number       :string
#  automatic_sms_activated_at :datetime
#  calendly_event_type_uris   :jsonb
#  calendly_user_uri          :string
#  can_export_data            :boolean          default(FALSE), not null
#  can_send_automatic_sms     :boolean          default(TRUE), not null
#  can_treat_task             :boolean          default(FALSE), not null
#  current_sign_in_at         :datetime
#  current_sign_in_ip         :inet
#  email                      :string           default(""), not null
#  encrypted_password         :string           default(""), not null
#  group_subscriptions        :jsonb            not null
#  is_disabled                :boolean          default(FALSE)
#  last_sign_in_at            :datetime
#  last_sign_in_ip            :inet
#  name                       :string
#  otp_attempts               :integer          default(0), not null
#  otp_code_digest            :string
#  otp_sent_at                :datetime
#  phone_number               :string
#  remember_created_at        :datetime
#  reset_password_sent_at     :datetime
#  reset_password_token       :string
#  sign_in_count              :integer          default(0), not null
#  two_factor_enabled         :boolean          default(FALSE), not null
#  user_role                  :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  aircall_number_id          :bigint
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

FactoryBot.define do
  factory :admin_user do
    name { Faker::Name.name }
    user_role { AdminUser::ROLES.sample }
    email { Faker::Internet.email }
    password { '(Strass07591)' }
    aircall_phone_number { Faker::Number.number(digits: 10) }
    aircall_number_id { Faker::Number.number(digits: 10) }
  end
end
