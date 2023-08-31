class Group

  class ProgramService

    attr_reader :errors

    def initialize(group)
      @errors = []
      @group = group
    end

    def call
      check_group_is_ready
      if @errors.empty?
        program_first_support_module
        fill_parents_available_support_modules
        verify_available_module_list
        create_call2_children_support_module
        select_default_support_module
        verify_chosen_modules
        program_check_spothit_credits
        program_sms_to_choose_module_to_parents
        program_support_module_sms
        @group.update(is_programmed: true)
      end

      self
    end

    private

    def check_group_is_ready
      @errors << 'Date de début obligatoire.' unless @group.started_at.present?
      @errors << 'Date de début ne pas être dans le passé.' if @group.started_at.present? && @group.started_at.past?
      @errors << 'Date de début doit être un Lundi.' if @group.started_at.present? && !@group.started_at.monday?
      @errors << "Il n'y a pas d'enfant dans la cohorte." if @group.children.size.zero?
      @errors << 'Il faut au moins 2 modules de prévu.' if @group.support_modules_count < 2
      @errors << 'La cohorte a déjà été programmé.' if @group.is_programmed
    end

    def program_first_support_module
      return if @group.support_modules_count < 1

      program_module_date = @group.started_at
      ChildrenSupportModule::ProgramFirstSupportModuleJob.set(wait_until: program_module_date.to_datetime.change(hour: 6)).perform_later(@group.id, program_module_date)
    end

    def fill_parents_available_support_modules
      return if @group.support_modules_count < 2

      (2..@group.support_modules_count).each do |module_index|
        fill_date = @group.started_at + ((module_index - 1) * 8.weeks) - 6.weeks
        ChildrenSupportModule::FillParentsAvailableSupportModulesJob.set(wait_until: fill_date.to_datetime.change(hour: 6)).perform_later(@group.id, module_index == 2)
      end
    end

    def verify_available_module_list
      return if @group.support_modules_count < 2

      (2..@group.support_modules_count).each do |module_index|
        verification_date = @group.started_at + ((module_index - 1) * 8.weeks) - 5.weeks
        ChildrenSupportModule::VerifyAvailableModulesTaskJob.set(wait_until: verification_date.to_datetime.change(hour: 6)).perform_later(@group.id)
      end
    end

    def create_call2_children_support_module
      return if @group.support_modules_count < 2

      creation_date = @group.started_at + 3.weeks + 2.days
      ChildrenSupportModule::CreateChildrenSupportModuleJob.set(wait_until: creation_date.to_datetime.change(hour: 6)).perform_later(@group.id)
    end

    def program_sms_to_choose_module2_to_parents
      select_module_date = ((@group.started_at + 8.weeks) - 4.weeks).next_occurring(:saturday)
      ChildrenSupportModule::SelectModuleJob.set(wait_until: select_module_date.to_datetime.change(hour: 6)).perform_later(@group.id, select_module_date, true)
    end

    def select_default_support_module
      return if @group.support_modules_count < 1

      (2..@group.support_modules_count).each do |module_index|
        selection_date = @group.started_at + ((module_index - 1) * 8.weeks) - 2.weeks - 1.day
        ChildrenSupportModule::SelectDefaultSupportModuleJob.set(wait_until: selection_date.to_datetime.change(hour: 6)).perform_later(@group.id)
      end
    end

    def verify_chosen_modules
      return if @group.support_modules_count < 2

      (2..@group.support_modules_count).each do |module_index|
        verification_date = @group.started_at + ((module_index - 1) * 8.weeks) - 2.weeks
        ChildrenSupportModule::VerifyChosenModulesTaskJob.set(wait_until: verification_date.to_datetime.change(hour: 6)).perform_later(@group.id)
      end
    end

    def program_check_spothit_credits
      return if @group.support_modules_count < 2

      (2..@group.support_modules_count).each do |module_index|
        check_date = @group.started_at + ((module_index - 1) * 8.weeks) - 1.week
        ChildrenSupportModule::CheckCreditsForGroupJob.set(wait_until: check_date.to_datetime.change(hour: 6)).perform_later(@group.id)
      end
    end

    def program_sms_to_choose_module_to_parents
      return if @group.support_modules_count < 3

      (3..@group.support_modules_count).each do |module_index|
        select_module_date = (@group.started_at + ((module_index - 1) * 8.weeks) - 4.weeks).next_occurring(:saturday)
        ChildrenSupportModule::SelectModuleJob.set(wait_until: select_module_date.to_datetime.change(hour: 6)).perform_later(@group.id, select_module_date)
      end
    end

    def program_support_module_sms
      return if @group.support_modules_count < 2

      (2..@group.support_modules_count).each do |module_index|
        program_module_date = @group.started_at + ((module_index - 1) * 8.weeks)
        ChildrenSupportModule::ProgramSupportModuleSmsJob.set(wait_until: program_module_date.to_datetime.change(hour: 6)).perform_later(@group.id, program_module_date)
      end
    end
  end
end
