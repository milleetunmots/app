FactoryBot.define do
  factory :blocked_send_attempt do
    provider { 'spothit' }
    kind { 'url' }
    detected_values { ['https://non-whitelisted.example.com/page'] }
    message_body { 'Regardez ceci : https://non-whitelisted.example.com/page' }
    replay_params do
      {
        planned_date: Time.zone.today.to_s,
        planned_hour: Time.zone.now.strftime('%H:%M'),
        recipients: [],
        message: 'Regardez ceci : https://non-whitelisted.example.com/page',
        rcs_media_id: nil,
        redirection_target_id: nil,
        quit_message: false,
        workshop_id: nil,
        supporter: nil,
        group_status: ['active'],
        provider: 'spothit',
        aircall_number_id: nil
      }
    end
  end
end
