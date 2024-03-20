class ChildrenSupportModule
  class SendReminder
    attr_reader :errors

    def initialize(children_support_module, reminder_date, second_reminder)
      @children_support_module = children_support_module
      @child = children_support_module.child
      @parent = children_support_module.parent
      @reminder_date = reminder_date
      @second_reminder = second_reminder
      @errors = []
    end

    def call
      selection_link = Rails.application.routes.url_helpers.children_support_module_link_url(
        @children_support_module.id,
        sc: @parent.security_code
      )

      message =
        if @second_reminder
          "1001mots : dernière chance pour choisir votre prochain thème pour que #{@child.first_name} reçoive son prochain livre ! #{selection_link}"
        else
          "1001mots : pour recevoir le prochain livre de 1001mots pour #{@child.first_name}, n'oubliez pas de choisir votre thème en cliquant sur ce lien : #{selection_link}"
        end

      message += '. Si vous ne faites pas de choix, l’accompagnement 1001mots prendra fin.' if (@child.child_support.tag_list & ['estimé-desengagé', 'estimées-désengagées-T1']).present?

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
