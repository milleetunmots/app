class ChildSupport::SelectModuleService

  attr_reader :errors

  def initialize(child, planned_date, planned_hour, module_index)
    @child = child
    @planned_date = planned_date
    @planned_hour = planned_hour
    @module_index = module_index
    @errors = []
  end

  def call
    if !@child.should_contact_parent1 && !@child.should_contact_parent2
      @errors << 'Aucun des parents ne veut être contacté'

      return self
    end

    send_select_module_message(@child.parent1, @child.child_support.parent1_available_support_module_list) if @child.should_contact_parent1
    send_select_module_message(@child.parent2, @child.child_support.parent2_available_support_module_list) if @child.parent2 && @child.should_contact_parent2
    self
  end

  private

  def send_select_module_message(parent, available_support_module_list)
    return if available_support_module_list.blank?
    return if available_support_module_list.reject(&:blank?).empty?

    @children_support_module = ChildrenSupportModule.find_by(child_id: @child.id, parent_id: parent.id, is_programmed: false)
    @children_support_module ||= ChildrenSupportModule.create!(child_id: @child.id, parent_id: parent.id, available_support_module_list: available_support_module_list, module_index: @module_index)

    if @children_support_module.available_support_module_list.reject(&:blank?).size == 1
      chose_support_module
    else
      send_message_to_parent(parent)
    end
  end

  def send_message_to_parent(parent)
    selection_link = Rails.application.routes.url_helpers.children_support_module_link_url(
      @children_support_module.id,
      sc: parent.security_code
    )

    # module_index starts with 1
    # so if module_index == 3 it means this is "Module 2" (that comes after "Module 0" and "Module 1")
    date = @module_index.eql?(3) && @child.group.with_module_zero? ? 'deux jours' : 'quelques jours'

    message = if @child.child_support.tag_list.include?('estimé-desengagé')
                "1001mots: C’est le moment de choisir votre prochain thème pour #{@child.first_name} en cliquant sur le lien #{selection_link}. Si vous ne faites pas de choix, l’accompagnement 1001mots prendra fin."
              elsif @child.child_support.tag_list.include?('estimées-désengagées-T1')
                "1001mots : Cliquez sur le lien pour choisir votre prochain thème pour #{@child.first_name} et recevoir un nouveau livre. Attention l'accompagnement s'arrêtera si vous ne choisissez pas avant la fin de semaine. #{selection_link}"
              else
                "1001mots : Cliquez sur le lien pour choisir votre prochain thème pour #{@child.first_name} et recevoir un nouveau livre. Attention dans #{date}, nous choisirons à votre place ! #{selection_link}"
              end

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
      is_module_3 = @child.group.with_module_zero? ? @module_index.eql?(4) : @module_index.eql?(3)
      ChildrenSupportModule::CheckToSendReminderJob.set(wait_until: reminder_date.to_datetime.change(hour: 6)).perform_later(@children_support_module.id, reminder_date)
      # second reminder only for Module 3
      ChildrenSupportModule::CheckToSendReminderJob.set(wait_until: (reminder_date + 2.days).to_datetime.change(hour: 6)).perform_later(@children_support_module.id, reminder_date + 2.days, true) if is_module_3
    end
  end

  def chose_support_module
    @children_support_module.update(support_module_id: @children_support_module.available_support_module_list.reject(&:blank?).first)
    @errors += @children_support_module.errors.full_messages if @children_support_module.errors.any?
  end
end
