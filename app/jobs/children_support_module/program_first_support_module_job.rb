class ChildrenSupportModule

  class ProgramFirstSupportModuleJob < ApplicationJob

    def perform(group_id, program_date)
      Group::StopSupportService.new(group_id, end_of_support: false, initial_modules: true).call
      ChildrenSupportModule::ProgramService.new.call(group_id, program_date, SupportModule::AGE_RANGE_LIST, SupportModule::READING)
    end
  end
end
