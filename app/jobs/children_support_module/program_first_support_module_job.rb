class ChildrenSupportModule

  class ProgramFirstSupportModuleJob < ApplicationJob

    def perform(group_id, program_date)
      group = Group.find(group_id)
      stop_support_service = Group::StopSupportService.new(group.id, true).call
      unless stop_support_service.errors.any?
        group.stopped_supports_count += stop_support_service.stopped_count
        group.save
      end

      ChildrenSupportModule::ProgramService.new.call(group_id, program_date, SupportModule::AGE_RANGE_LIST, SupportModule::READING)
    end
  end
end
