module Calendly
  class SyncUsersAndEventTypesJob < ApplicationJob

    CALL_NUMBERS = [0, 1, 2, 3].freeze

    def perform
      sync_calendly_user_uris
      create_missing_event_types
    end

    private

    def sync_calendly_user_uris
      service = Calendly::FillAdminUserCalendlyUserUriService.new.call
      Rollbar.error(service.errors) if service.errors.any?
    end

    def create_missing_event_types
      admin_users_with_calendly.find_each do |user|
        missing_call_numbers(user).each do |call_number|
          create_event_type(user, call_number)
        end
      end
    end

    def admin_users_with_calendly
      AdminUser.where.not(calendly_user_uri: nil).where.not(aircall_phone_number: nil)
    end

    def missing_call_numbers(user)
      existing_keys = user.calendly_event_type_uris&.keys || []
      CALL_NUMBERS.reject { |n| existing_keys.include?("call#{n}") }
    end

    def create_event_type(user, call_number)
      service = Calendly::CreateEventTypeService.new(
        name: "Appel #{call_number}",
        calendly_user_uri: user.calendly_user_uri,
        aircall_phone_number: user.aircall_phone_number,
        call_number: call_number
      ).call
      Rollbar.error(service.errors) if service.errors.any?
    end
  end
end
