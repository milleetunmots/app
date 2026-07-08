class AdminUser

  class ImportGroupSubscriptionsJob < ApplicationJob

    def perform
      service = AdminUser::ImportGroupSubscriptionsService.new.call
      return if service.errors.empty?

      Rollbar.error('AdminUser::ImportGroupSubscriptionsJob', errors: service.errors)
    end
  end
end
