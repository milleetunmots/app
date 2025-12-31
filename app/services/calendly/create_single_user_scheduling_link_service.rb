module Calendly
  class CreateSingleUserSchedulingLinkService < Calendly::ApiBase

    attr_reader :errors

    def initialize(admin_user_id:, child_support_id:)
      @errors = []
      @admin_user = AdminUser.find_by(id: admin_user_id)
      @child_support = ChildSupport.find_by(id: child_support_id)
    end

    def call
      unless @admin_user
        @errors << {
          message: "L'utilisateur n'a pas été trouvé" }
        return self
      end
      unless @child_support
        @errors << { message: "La fiche de suivi n'a pas été trouvé" }
        return self
      end
      response = http_client_with_auth.post(
        build_url(SINGLE_USE_SCHEDULING_LINK_ENDPOINT),
        form: {
          max_event_count: 1,
          owner: @admin_user.calendly_event_type_uri,
          owner_type: 'EventType'
        }
      )
      status = response.status
      response = JSON.parse(response.body)
      if status.success?
        @child_support.update(calendly_booking_url: response['resource']['booking_url'])
      else
        @errors << {
          message: 'La création du lien à usage unique a échoué',
          details: response['details'],
          child_support_id: @child_support.id,
          admin_user_id: @admin_user.id
        }
      end
      self
    end
  end
end
