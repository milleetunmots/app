class Group
  class ProgramService

    attr_reader :errors

    def initialize(group)
      @errors = []
      @group = group
    end

    def call
      check_group_is_ready
      program_sms_to_choose_module_to_parents if @errors.empty?
      program_support_module_sms if @errors.empty?
      @group.update(is_programmed: true) if @errors.empty?

      self
    end

    private

    def check_group_is_ready
      @errors << "Date de début obligatoire." unless @group.started_at.present?
      @errors << "Date de début ne pas être dans le passé." if @group.started_at.present? && @group.started_at.past?
      @errors << "Date de début doit être un Lundi." if @group.started_at.present? && !@group.started_at.monday?
      @errors << "Il n'y a pas d'enfant dans la cohorte." if @group.children.size.zero?
      @errors << "Il faut au moins 2 modules de prévu." if @group.support_modules_count < 2
      @errors << "La cohorte a déjà été programmé." if @group.is_programmed
    end

    def program_sms_to_choose_module_to_parents
      return if @group.support_modules_count < 3

      (3..@group.support_modules_count).each do |module_index|
        select_module_date = (@group.started_at + (module_index - 1) * 8.weeks - 4.weeks).next_occurring(:saturday)

        ChildrenSupportModule::SelectModuleJob.set(wait_until: select_module_date.to_datetime.change(hour: 6)).perform_later(@group.id, select_module_date)
      end
    end

    def program_support_module_sms
      return if @group.support_modules_count < 2

      (2..@group.support_modules_count).each do |module_index|
        program_module_date = @group.started_at + (module_index - 1) * 8.weeks

        ChildrenSupportModule::ProgramSupportModuleSmsJob.set(wait_until: program_module_date.to_datetime.change(hour: 6)).perform_later(@group.id, program_module_date)
      end
    end
  end
end
