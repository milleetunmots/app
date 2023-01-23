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
        start_module_date = @group.started_at + (module_index - 1) * 8.weeks - 4.weeks

        ChildrenSupportModule::SelectModuleJob.set(wait_until: start_module_date.noon).perform_later(@group.id)
      end
    end
  end
end
