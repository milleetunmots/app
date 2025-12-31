module Calendly
  class FillAdminUserCalendlyUserUri

    attr_reader :errors, :admin_users

    def initialize
      @errors = []
      @admin_users = []
    end

    def call
      retrieve_organization_memberships_service = Calendly::RetrieveOrganizationMembershipsService.new.call
      @errors << { service: 'FillAdminUserCalendlyUserUri', erreurs: retrieve_organization_memberships_service.errors }

      users = retrieve_organization_memberships_service.users
      users.each do |user|
        admin_user = AdminUser.find_by(email: user['email'])
        next unless admin_user
        next if admin_user.calendly_user_uri.present?

        @admin_users << admin_user if admin_user.update(calendly_user_uri: user['uri'])
      end
      self
    end
  end
end
