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

    send_select_module_message(@child.parent1) if @child.should_contact_parent1
    send_select_module_message(@child.parent2) if @child.parent2 && @child.should_contact_parent2

    self
  end

  private

  def send_select_module_message(parent)
    @child_support_module = ChildrenSupportModule.create!(child_id: @child.id, parent_id: parent.id)

    selection_link = Rails.application.routes.url_helpers.edit_children_support_module_url(
      @child_support_module.id,
      :security_code => parent.security_code
    )

    message = "Lien: #{selection_link}"

    sms_service = SpotHit::SendSmsService.new(
      parent.id,
      DateTime.now,
      message
    ).call

    @errors += sms_service.errors if sms_service.errors.any?
  end

end
