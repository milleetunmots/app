class ChildrenSupportModule
  class SendReminder
    attr_reader :errors

    def initialize(children_support_module)
      @children_support_module = children_support_module
      @child = children_support_module.child
      @parent = children_support_module.parent
      @errors = []
    end

    def call
      selection_link = Rails.application.routes.url_helpers.edit_children_support_module_url(
        @children_support_module.id,
        :security_code => @parent.security_code
      )

      message = "1001mots : N'oubliez pas de choisir votre prochain thème pour que #{@child.first_name} reçoive son prochain livre ! #{selection_link}"

      sms_service = SpotHit::SendSmsService.new(
        @parent.id,
        DateTime.now,
        message
      ).call

      @errors += sms_service.errors if sms_service.errors.any?

      self
    end
  end
end
