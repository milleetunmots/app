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
