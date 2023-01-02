class ChildSupport::ProgramChosenModulesService

  attr_reader :errors

  def initialize
    @chosen_modules_service = ChildrenSupportModule.includes(:parent).with_support_module.not_programmed
    @errors = []
  end

  def call
    check_module_not_started
    return self if @errors.any?

    @chosen_modules_service.group_by(&:support_module_id).each do |support_module_id, children_support_modules|
      support_module = SupportModule.find(support_module_id)

      service = SupportModule::ProgramService.new(
        support_module,
        recipients: children_support_modules.map {|csm| "parent.#{csm.parent_id}"}
      ).call

      raise service.errors.join("\n") if service.errors.any?

      ChildrenSupportModule.where(id: children_support_modules.map(&:id)).update_all(is_programmed: true)

      # to avoid sending to many api calls to spot-hit, sleep 60 seconds between each module
      sleep(60)
    rescue StandardError => e
      parent_names = children_support_modules.map { |csm| csm.parent.decorate.name }.join(", ")
      @errors << "Erreur en programmant le module #{support_module.name} pour les parents suivant: #{parent_names}.\n il est possible qu'une partie des messages ai été programmé. Erreur technique : #{e.message}"
    end

    self
  end

  private

  def check_module_not_started
    # already_started = @chosen_modules_service.where(modules: { start_at: DateTime::Infinity.new..Date.yesterday })

    # @errors <<
  end

end
