# == Schema Information
#
# Table name: scheduled_calls
#
#  id                   :bigint           not null, primary key
#  calendly_event_uri   :string           not null
#  calendly_invitee_uri :string
#  call_session         :integer
#  canceled_at          :datetime
#  cancellation_reason  :text
#  duration_minutes     :integer
#  event_type_name      :string
#  event_type_uri       :string
#  invitee_comment      :text
#  invitee_email        :string
#  invitee_name         :string
#  raw_payload          :jsonb
#  scheduled_at         :datetime
#  status               :string           default("scheduled"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  admin_user_id        :bigint
#  child_support_id     :bigint
#  parent_id            :bigint
#
# Indexes
#
#  index_scheduled_calls_on_admin_user_id       (admin_user_id)
#  index_scheduled_calls_on_calendly_event_uri  (calendly_event_uri) UNIQUE
#  index_scheduled_calls_on_child_support_id    (child_support_id)
#  index_scheduled_calls_on_parent_id           (parent_id)
#  index_scheduled_calls_on_scheduled_at        (scheduled_at)
#  index_scheduled_calls_on_status              (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (child_support_id => child_supports.id)
#  fk_rails_...  (parent_id => parents.id)
#
FactoryBot.define do
  factory :scheduled_call do
    sequence(:calendly_event_uri) { |n| "https://api.calendly.com/scheduled_events/#{SecureRandom.uuid}-#{n}" }
    call_session { (0..3).to_a.sample }
    status { 'scheduled' }
    scheduled_at { 1.day.from_now }
    duration_minutes { 30 }
    event_type_name { 'Appel de suivi' }
    invitee_email { Faker::Internet.email }
    invitee_name { Faker::Name.name }

    trait :with_admin_user do
      association :admin_user
    end

    trait :with_child_support do
      association :child_support
    end

    trait :with_parent do
      association :parent
    end

    trait :canceled do
      status { 'canceled' }
      canceled_at { Time.zone.now }
      cancellation_reason { 'Annulé par le parent' }
    end

    trait :past do
      scheduled_at { 1.day.ago }
    end

    trait :upcoming do
      status { 'scheduled' }
      scheduled_at { 1.day.from_now }
    end
  end
end
