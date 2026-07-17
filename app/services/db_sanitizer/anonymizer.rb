# frozen_string_literal: true

module DbSanitizer
  class Anonymizer
    SAFE_PHONE = '+33800000000'

    def call
      anonymize_parents
      anonymize_children
      anonymize_child_supports
      anonymize_child_support_call_archives
      anonymize_parents_registrations
      anonymize_scheduled_calls
    end

    private

    def anonymize_parents
      # Fixed values for all records
      Parent.update_all(
        phone_number: SAFE_PHONE,
        phone_number_national: SAFE_PHONE,
        aircall_id: nil,
        address_supplement: nil,
        latitude: nil,
        longitude: nil,
        mid_term_speech: nil,
        is_ambassador_detail: nil
      )
      Parent.update_all("aircall_datas = '{}', calendly_booking_urls = '{}', calendly_last_booking_dates = '{}'")

      # Unique values per record via SQL
      Parent.where.not(email: nil).update_all("email = 'parent_' || id || '@example.com'")
      Parent.update_all("security_token = md5(random()::text) || md5(random()::text)")
      Parent.update_all("security_code = left(md5(random()::text), 2)")
      Parent.update_all("address = 'Adresse fictive ' || id")
      Parent.update_all("city_name = 'Ville fictive'")

      # Faker for names (deterministic by ID)
      Parent.find_each do |parent|
        Faker::Config.random = Random.new(parent.id)
        last_name = Faker::Name.last_name
        first_name = Faker::Name.first_name
        parent.update_columns(
          first_name: first_name,
          last_name: last_name,
          letterbox_name: parent.letterbox_name.present? ? last_name : nil,
          job: parent.job.present? ? Faker::Job.title : nil
        )
      end
      Faker::Config.random = nil
    end

    def anonymize_children
      Child.update_all("security_code = left(md5(random()::text), 2)")
      Child.update_all("security_token = md5(random()::text) || md5(random()::text)")

      Child.find_each do |child|
        Faker::Config.random = Random.new(child.id)
        child.update_columns(
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name
        )
      end
      Faker::Config.random = nil
    end

    def anonymize_child_supports
      null_fields = %w[
        notes important_information
        stop_support_details restart_support_details parent_needs
        instagram_user instagram_follower
      ]
      (0..3).each do |n|
        null_fields += [
          "call#{n}_notes", "call#{n}_goals", "call#{n}_goals_sms",
          "call#{n}_goals_tracking", "call#{n}_technical_information",
          "call#{n}_language_development", "call#{n}_parent_actions",
          "call#{n}_status_details", "call#{n}_sendings_benefits_details",
          "call#{n}_why_talk_needed"
        ]
      end
      # call0 has no goals_tracking column
      null_fields.delete('call0_goals_tracking')
      # call0 has no avoid_disengagement_details column
      (1..3).each do |n|
        null_fields << "call#{n}_avoid_disengagement_details"
      end

      ChildSupport.update_all(null_fields.index_with(nil))
      ChildSupport.update_all(other_phone_number: SAFE_PHONE)
    end

    def anonymize_child_support_call_archives
      archive_null_fields = []
      (4..5).each do |n|
        archive_null_fields += [
          "call#{n}_notes", "call#{n}_goals", "call#{n}_goals_sms",
          "call#{n}_goals_tracking", "call#{n}_technical_information",
          "call#{n}_language_development", "call#{n}_parent_actions",
          "call#{n}_status_details", "call#{n}_sendings_benefits_details",
          "call#{n}_why_talk_needed"
        ]
      end

      ChildSupportCallArchive.update_all(archive_null_fields.index_with(nil))
    end

    def anonymize_parents_registrations
      ParentsRegistration.update_all(
        parent1_phone_number: SAFE_PHONE,
        parent2_phone_number: SAFE_PHONE
      )
    end

    def anonymize_scheduled_calls
      ScheduledCall.update_all(
        invitee_email: nil,
        invitee_name: nil,
        invitee_comment: nil,
        cancellation_reason: nil
      )
      ScheduledCall.update_all("raw_payload = '{}'")
    end
  end
end
