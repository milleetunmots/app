class ChildrenSupportModule

  class ProgramSupportModuleZeroJob < ApplicationJob

    def perform(group_id, program_date)
      Group::StopSupportService.new(group_id, true).call
      ChildrenSupportModule::ProgramService.new.call(group_id, program_date, SupportModule::MODULE_ZERO_AGE_RANGE_LIST, SupportModule::LANGUAGE_MODULE_ZERO)
    end
  end
end
