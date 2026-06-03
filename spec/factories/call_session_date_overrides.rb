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
FactoryBot.define do
  factory :call_session_date_override do
    association :admin_user
    association :group
    call_session { 0 }
    start_date { group.send(:"call#{call_session}_start_date") + 1.day }
    end_date { group.send(:"call#{call_session}_end_date") - 1.day }
  end
end
