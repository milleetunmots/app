class ChildSupport::ProgramChosenModulesService

  attr_reader :errors

  def initialize(children_support_module_ids, first_message_date)
    @chosen_modules_service = ChildrenSupportModule.includes(:parent, child: :child_support).with_support_module.not_programmed.where(id: children_support_module_ids)
    @first_message_date = first_message_date
    @errors = []
  end

  def call
    @chosen_modules_service.group_by(&:support_module_id).each do |support_module_id, children_support_modules|
      support_module = SupportModule.find(support_module_id)
      group = @chosen_modules_service.first.child.group

      if group.nil?
        @errors << 'Cohorte introuvable'
        raise @errors.join('\n')
      end

      service = SupportModule::ProgramService.new(
        support_module,
        @first_message_date,
        recipients: children_support_modules.map {|csm| "parent.#{csm.parent_id}"},
        first_support_module: group.support_module_programmed.zero?
      ).call

      raise service.errors.join("\n") if service.errors.any?

      ChildrenSupportModule.where(id: children_support_modules.map(&:id)).update_all(is_programmed: true)

      # to avoid sending to many api calls to spot-hit, sleep 60 seconds between each module
      sleep(60)
    rescue StandardError => e
      parent_names = children_support_modules.map { |csm| csm.parent.decorate.name }.join(", ")
      @errors << "Erreur en programmant le module #{support_module.name} pour les parents suivant: #{parent_names}.\n il est possible qu'une partie des messages ai été programmé. Erreur technique : #{e.message}"
    end

    clean_support_module_list
    self
  end

  private

  def clean_support_module_list
    @chosen_modules_service.each do |csm|
      csm.child.child_support&.update(parent1_available_support_module_list: [], parent2_available_support_module_list: [])
    end
  end
end
