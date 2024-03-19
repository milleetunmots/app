class Group

  class ProgramService

    MODULE_ZERO_DURATION = 4.weeks.freeze

    attr_reader :errors

    def initialize(group)
      @errors = []
      @group = group
    end

    def call
      check_group_is_ready
      if @errors.empty?
        # making sure hours are within 1 - 8
        @hour = (@group.started_at.month % 10).clamp(1, 8)
        program_support_module_zero
        program_sms_to_bilinguals
        assign_default_call_status(0)
        program_first_support_module
        assign_default_call_status(1)
        fill_parents_available_support_modules
        verify_available_module_list
        create_call2_children_support_module
        select_default_support_module2
        verify_chosen_modules2
        program_check_spothit_credits_module2
        assign_default_call_status(2)
        program_sms_to_choose_module2_to_parents
        program_sms_to_choose_module_to_parents
        assign_default_call_status(3)
        select_default_support_module
        verify_chosen_modules
        program_check_spothit_credits
        program_support_module_sms
        stop_support
        @group.update(is_programmed: true)
      end

      self
    end

    private

    def check_group_is_ready
      @errors << 'Date de début obligatoire.' if @group.started_at.blank?
      @errors << 'Date de début ne pas être dans le passé.' if @group.started_at.present? && @group.started_at.past?
      @errors << 'Date de début doit être un Lundi.' if @group.started_at.present? && !@group.started_at.monday?
      @errors << "Il n'y a pas d'enfant dans la cohorte." if @group.children.size.zero?
      @errors << 'Il faut au moins 3 modules de prévu (en comptant les modules 0 et 1).' if @group.support_modules_count < 3
      @errors << 'La cohorte a déjà été programmé.' if @group.is_programmed
    end

    def program_support_module_zero
      return unless @group.support_module_programmed.zero?

      program_module_date = @group.started_at
      ChildrenSupportModule::ProgramSupportModuleZeroJob.set(wait_until: program_module_date.to_datetime.change(hour: @hour)).perform_later(@group.id, program_module_date)
    end

    def program_sms_to_bilinguals
      bilinguals_first_sms_date = @group.started_at + 2.weeks
      Group::ProgramSmsToBilingualsJob.set(wait_until: bilinguals_first_sms_date.to_datetime.change(hour: @hour)).perform_later(@group.id, bilinguals_first_sms_date)
    end

    def program_first_support_module
      program_module_date = @group.started_at + MODULE_ZERO_DURATION
      ChildrenSupportModule::ProgramFirstSupportModuleJob.set(wait_until: program_module_date.to_datetime.change(hour: @hour)).perform_later(@group.id, program_module_date)
    end

    def assign_default_call_status(call_number)
      default_status_date =
        case call_number
        when 0
          @group.started_at + 3.weeks
        when 1
          @group.started_at + 7.weeks
        when 2
          @group.started_at + 11.weeks
        when 3
          @group.started_at + 26.weeks
        end
      ChildSupport::AssignDefaultCallStatusJob.set(wait_until: default_status_date.to_datetime.change(hour: @hour - 1)).perform_later(@group.id, call_number)
    end

    def fill_parents_available_support_modules
      (3..@group.support_modules_count).each do |module_index|
        fill_date = @group.started_at + ((module_index - 2) * 8.weeks) - 6.weeks + MODULE_ZERO_DURATION
        ChildrenSupportModule::FillParentsAvailableSupportModulesJob.set(wait_until: fill_date.to_datetime.change(hour: @hour)).perform_later(@group.id, module_index == 3)
      end
    end

    def verify_available_module_list
      (3..@group.support_modules_count).each do |module_index|
        verification_date = @group.started_at + ((module_index - 2) * 8.weeks) - 5.weeks + MODULE_ZERO_DURATION
        ChildrenSupportModule::VerifyAvailableModulesTaskJob.set(wait_until: verification_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
      end
    end

    def create_call2_children_support_module
      creation_date = @group.started_at + 3.weeks + 2.days + MODULE_ZERO_DURATION
      ChildrenSupportModule::CreateChildrenSupportModuleJob.set(wait_until: creation_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
    end

    def program_sms_to_choose_module2_to_parents
      # "Module 2" ==> module_index 3
      select_module_date = @group.started_at + 6.weeks + MODULE_ZERO_DURATION
      ChildrenSupportModule::SelectModuleJob.set(wait_until: select_module_date.to_datetime.change(hour: @hour)).perform_later(@group.id, select_module_date, 3)
    end

    def program_sms_to_choose_module_to_parents
      return if @group.support_modules_count < 3

      (4..@group.support_modules_count).each do |module_index|
        select_module_date = (@group.started_at + ((module_index - 2) * 8.weeks) - 4.weeks + MODULE_ZERO_DURATION).next_occurring(:monday)
        ChildrenSupportModule::SelectModuleJob.set(wait_until: select_module_date.to_datetime.change(hour: @hour)).perform_later(@group.id, select_module_date, module_index)
      end
    end

    def select_default_support_module
      (4..@group.support_modules_count).each do |module_index|
        selection_date = @group.started_at + ((module_index - 2) * 8.weeks) - 2.weeks - 1.day + MODULE_ZERO_DURATION
        ChildrenSupportModule::SelectDefaultSupportModuleJob.set(wait_until: selection_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
      end
    end

    def select_default_support_module2
      select_module_date = @group.started_at + 7.weeks + MODULE_ZERO_DURATION
      ChildrenSupportModule::SelectDefaultSupportModuleJob.set(wait_until: select_module_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
    end

    def verify_chosen_modules
      (4..@group.support_modules_count).each do |module_index|
        verification_date = @group.started_at + ((module_index - 2) * 8.weeks) - 2.weeks + MODULE_ZERO_DURATION
        ChildrenSupportModule::VerifyChosenModulesTaskJob.set(wait_until: verification_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
      end
    end

    def verify_chosen_modules2
      select_module_date = @group.started_at + 7.weeks + MODULE_ZERO_DURATION
      ChildrenSupportModule::VerifyChosenModulesTaskJob.set(wait_until: select_module_date.to_datetime.change(hour: @hour + 1)).perform_later(@group.id)
    end

    def program_check_spothit_credits
      (4..@group.support_modules_count).each do |module_index|
        check_date = @group.started_at + ((module_index - 2) * 8.weeks) - 1.week + MODULE_ZERO_DURATION
        ChildrenSupportModule::CheckCreditsForGroupJob.set(wait_until: check_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
      end
    end

    def program_check_spothit_credits_module2
      select_module_date = @group.started_at + 7.weeks + 2.days + MODULE_ZERO_DURATION
      ChildrenSupportModule::CheckCreditsForGroupJob.set(wait_until: select_module_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
    end

    def program_support_module_sms
      return if @group.support_modules_count < 2

      (3..@group.support_modules_count).each do |module_index|
        program_module_date = @group.started_at + ((module_index - 2) * 8.weeks) + MODULE_ZERO_DURATION
        ChildrenSupportModule::ProgramSupportModuleSmsJob.set(wait_until: program_module_date.to_datetime.change(hour: @hour)).perform_later(@group.id, program_module_date)
      end
    end

    def stop_support
      end_support_date = @group.started_at + ((@group.support_modules_count - 2) * 8.weeks) + 4.weeks + MODULE_ZERO_DURATION
      Group::StopSupportJob.set(wait_until: end_support_date.to_datetime.change(hour: @hour)).perform_later(@group.id)
    end
  end
end
