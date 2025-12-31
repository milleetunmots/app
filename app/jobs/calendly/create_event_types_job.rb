module Calendly
  class CreateEventTypesJob < ApplicationJob

    def perform
      fill_admin_user_calendly_user_uri_service = Calendly::FillAdminUserCalendlyUserUri.new.call
      Rollbar.error(fill_admin_user_calendly_user_uri_service.errors) if fill_admin_user_calendly_user_uri_service.errors.any?
      fill_admin_user_calendly_user_uri_service.admin_users.each do |user|
        create_event_type_service = Calendly::CreateEventTypeService.new(name: 'Rendez-vous', calendly_user_uri: user.calendly_user_uri, aircall_phone_number: user.aircall_phone_number).call
        Rollbar.error(create_event_type_service.errors) if create_event_type_service.errors.any?
      end
    end
  end
end
