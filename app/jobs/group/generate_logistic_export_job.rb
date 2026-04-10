class Group
  class GenerateLogisticExportJob < ApplicationJob
    def perform
      service = Group::GenerateLogisticExportService.new.call
      return if service.errors.empty?

      Rollbar.error('Group::GenerateLogisticExportJob', errors: service.errors)
    end
  end
end
