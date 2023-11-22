class ChildrenSupportModule

  class ProgramFirstSupportModuleJob < ApplicationJob

    def perform(group_id, program_date)
      ChildrenSupportModule::ProgramService.new.call(group_id, program_date, SupportModule::AGE_RANGE_LIST, SupportModule::READING)
    end
  end
end
