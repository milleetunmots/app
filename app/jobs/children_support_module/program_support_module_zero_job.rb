class ChildrenSupportModule

  class ProgramSupportModuleZeroJob < ApplicationJob

    def perform(group_id, program_date)
      group = Group.find(group_id)
      stop_support_service = Group::StopSupportService.new(group.id, true).call
      unless stop_support_service.errors.any?
        group.stopped_supports_count += stop_support_service.stopped_count
        group.save
      end

      ChildrenSupportModule::ProgramService.new.call(group_id, program_date, SupportModule::MODULE_ZERO_AGE_RANGE_LIST, SupportModule::LANGUAGE_MODULE_ZERO)
    end
  end
end
