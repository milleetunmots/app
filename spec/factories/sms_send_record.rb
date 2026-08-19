FactoryBot.define do
  factory :sms_send_record do
    admin_user
    recipients_count { 1 }
  end
end
