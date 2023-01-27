class ChildrenSupportModule
  class SendReminder
    attr_reader :errors

    def initialize(children_support_module, reminder_date)
      @children_support_module = children_support_module
      @child = children_support_module.child
      @parent = children_support_module.parent
      @reminder_date = reminder_date
      @errors = []
    end

    def call
      selection_link = Rails.application.routes.url_helpers.children_support_module_link_url(
        @children_support_module.id,
        sc: @parent.security_code
      )

      message = "1001mots : N'oubliez pas de choisir votre prochain thème pour que #{@child.first_name} reçoive son prochain livre ! #{selection_link}"

      sms_service = ProgramMessageService.new(
        @reminder_date,
        "12:30",
        ["parent.#{@parent.id}"],
        message
      ).call

      @errors += sms_service.errors if sms_service.errors.any?

      self
    end
  end
end
