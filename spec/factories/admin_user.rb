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
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
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
    password { Faker::Internet.password(min_length: 10, mix_case: true, special_characters: true) }
    aircall_phone_number { Faker::Number.number(digits: 10) }
    aircall_number_id { Faker::Number.number(digits: 10) }
  end
end
