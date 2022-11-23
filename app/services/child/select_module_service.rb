class Child::SelectModuleService

  attr_reader :errors

  def initialize(child)
    @child = child
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
    @child_support_module = ChildrenSupportModule.create!(child_id: @child.id, parent_id: parent.id, available_support_module_list: available_support_module_list)

    selection_link = Rails.application.routes.url_helpers.edit_children_support_module_url(
      @child_support_module.id,
      :security_code => parent.security_code
    )

    message = "1001mots : C'est le moment de choisir votre thème pour #{@child.first_name}. Cliquez ici pour recevoir le prochain livre et les messages #{selection_link}"

    sms_service = SpotHit::SendSmsService.new(
      parent.id,
      DateTime.now,
      message
    ).call

    @errors += sms_service.errors if sms_service.errors.any?
  end

end
