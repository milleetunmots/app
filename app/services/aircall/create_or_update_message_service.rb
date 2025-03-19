module Aircall
  class CreateOrUpdateMessageService

    attr_reader :errors, :message

    def initialize(payload:)
      @errors = []
      @payload = payload
      @attributes = {}
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

      @message = AircallMessage.find_or_initialize_by(aircall_id: @payload['id'])
      set_message_attributes
      return self if @errors.any?

      @message.assign_attributes(@attributes)
      @errors << "AircallMessage save error : #{@message.errors.full_messages}" unless @message.save
      self
    end

    private

    def set_message_attributes
      if @message.persisted? && @message.parent_id && @message.caller_id && @message.child_support_id && @message.body
        @attributes = { status: @payload['status'] }
      else
        external_number = @payload['external_number']
        aircall_phone_number = @payload['number']['digits']
        status = @payload['status'] || 'sent'

        parent = Parent.kept.where(
          phone_number: Phonelib.parse(external_number).e164
        ).order(Parent.arel_table[:aircall_id].not_eq(nil).desc, :aircall_id).first
        @errors << "AircallMessage n'a pas pu être traité : Parent avec numéro #{external_number} introuvable" unless parent
        admin_user = AdminUser.find_by(aircall_phone_number: Phonelib.parse(aircall_phone_number).e164)
        @errors << "AircallMessage n'a pas pu être traité : AdminUser avec numéro #{aircall_phone_number} introuvable" unless admin_user
        child_support_id = parent&.current_child&.child_support_id
        return if @errors.any?

        @attributes =
          {
            aircall_id: @payload['id'],
            status: status,
            parent_id: parent.id,
            caller_id: admin_user.id,
            child_support_id: child_support_id,
            body: @payload['body'],
            direction: status.eql?('received') ? 'inbound' : 'outbound'
          }
      end
    end
  end
end
