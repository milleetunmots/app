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
        status = @payload['status'] || 'sent'

        parent = Parent.kept.where(
          phone_number: Phonelib.parse(external_number).e164
        ).order(Parent.arel_table[:aircall_id].not_eq(nil).desc, :aircall_id).first
        @errors << "AircallMessage n'a pas pu être traité : Parent avec numéro #{external_number} introuvable" unless parent
        child_support = parent&.current_child&.child_support
        admin_user = find_admin_user(child_support)
        @errors << "AircallMessage #{@payload['id']} n'a pas pu être traité : accompagnante introuvable (numéro #{@payload.dig('number', 'digits').inspect}, user #{@payload.dig('user', 'id').inspect})" if parent && !admin_user
        return if @errors.any?

        @attributes =
          {
            aircall_id: @payload['id'],
            status: status,
            parent_id: parent.id,
            caller_id: admin_user.id,
            child_support_id: child_support&.id,
            body: @payload['body'],
            direction: status.eql?('received') ? 'inbound' : 'outbound'
          }
      end
    end

    # Aircall n'envoie pas toujours l'objet `number` : on se rabat sur l'utilisateur Aircall (message.sent)
    # puis sur l'accompagnante de la fiche (message.received, message.status_updated)
    def find_admin_user(child_support)
      aircall_phone_number = @payload.dig('number', 'digits')
      return AdminUser.find_by(aircall_phone_number: Phonelib.parse(aircall_phone_number).e164) if aircall_phone_number.present?

      find_admin_user_from_aircall_user || child_support&.supporter
    end

    def find_admin_user_from_aircall_user
      email = @payload.dig('user', 'email')
      name = @payload.dig('user', 'name')
      admin_user = AdminUser.find_by('LOWER(email) = ?', email.downcase.squish) if email.present?
      return admin_user if admin_user || name.blank?

      normalized_name = I18n.transliterate(name.downcase.squish)
      AdminUser.account_not_disabled.find { |user| I18n.transliterate(user.name.to_s.downcase.squish) == normalized_name }
    end
  end
end
