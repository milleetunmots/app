class ChildrenSupportModule
  class SendReminder
    REMINDER_BUNDLE = ['Relance du choix de thème', 'relance_choix_theme'].freeze
    LAST_CHANCE_BUNDLE = ['Relance de dernière chance', 'relance_derniere_chance'].freeze

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
      name, key = @second_reminder ? LAST_CHANCE_BUNDLE : REMINDER_BUNDLE
      bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
      return add_error(Media::TextMessagesBundle.missing_message(name: name, key: key)) unless bundle

      sms_service = ProgramAutomaticMessageService.new(
        @reminder_date, '12:30', ["parent.#{@parent.id}"],
        bundle.body1, bundle.rcs_media_id_to_send(1), bundle.redirection_target_id(1),
        automatic_message_key: key, recipient_variables: { @parent.id => message_variables }
      ).call

      @errors += sms_service.errors if sms_service.errors.any?

      self
    end

    private

    def message_variables
      {
        'LIEN_CHOIX_THEME' => Rails.application.routes.url_helpers.children_support_module_link_url(@children_support_module.id, sc: @parent.security_code),
        'PRENOM_ENFANT' => @child.first_name
      }
    end

    def add_error(message)
      @errors << message
      self
    end
  end
end
