class ChildSupport::SelectModuleService

  attr_reader :errors

  def initialize(child, planned_date, planned_hour)
    @child = child
    @planned_date = planned_date
    @planned_hour = planned_hour
    @errors = []
  end

  def call
    if !@child.should_contact_parent1 && !@child.should_contact_parent2
      @errors << "Aucun des parents ne veut être contacté"

      return self
    end

    send_select_module_message(@child.parent1, @child.child_support.parent1_available_support_module_list) if @child.should_contact_parent1
    send_select_module_message(@child.parent2, @child.child_support.parent2_available_support_module_list) if @child.parent2 && @child.should_contact_parent2
    self
  end

  private

  def send_select_module_message(parent, available_support_module_list)
    return if available_support_module_list.reject(&:blank?).empty?

    @children_support_module = ChildrenSupportModule.find_by(child_id: @child.id, parent_id: parent.id, is_programmed: false)
    @children_support_module ||= ChildrenSupportModule.create!(child_id: @child.id, parent_id: parent.id, available_support_module_list: available_support_module_list)

    selection_link = Rails.application.routes.url_helpers.children_support_module_link_url(
      @children_support_module.id,
      :sc => parent.security_code
    )

    message = "1001mots : C'est le moment de choisir votre thème pour #{@child.first_name}. Cliquez ici pour recevoir le prochain livre et les messages #{selection_link}"

    sms_service = ProgramMessageService.new(
      @planned_date,
      @planned_hour,
      ["parent.#{parent.id}"],
      message
    ).call

    if sms_service.errors.any?
      @errors += sms_service.errors
    else
      reminder_date = @planned_date.advance(days: 3)
      ChildrenSupportModule::CheckToSendReminderJob.set(wait_until: reminder_date.to_datetime.change(hour: 6)).perform_later(@children_support_module.id, reminder_date)
    end
  end

end
