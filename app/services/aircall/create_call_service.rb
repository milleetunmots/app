module Aircall
  class CreateCallService

    attr_reader :errors, :call

    def initialize(payload:)
      @errors = []
      @payload = payload
      @attributes = {}
    end

    def call
      # call_uuid in webhooks but sid in API - same value
      @call = AircallCall.find_or_initialize_by(call_uuid: @payload['call_uuid'].presence || @payload['sid'])
      set_call_attributes
      return self if @errors.any?

      @call.assign_attributes(@attributes)
      @errors << "AircallCall save error : #{@call.errors.full_messages}" unless @call.save
      self
    end

    private

    def set_call_attributes
      if @call.persisted?
        tag_names = @payload['tags'].map { |tag| tag['name'] }.compact
        comments = @payload['comments'].map { |comment| comment['content'] }.compact
        @attributes = { tags: tag_names, notes: comments }
      else
        new_call_attributes
      end
    end

    def new_call_attributes
      external_number = @payload['raw_digits']
      aircall_phone_number = @payload['number']['e164_digits']

      unless external_number.eql?('anonymous')
        parent = Parent.kept.where(
          phone_number: Phonelib.parse(external_number).e164
        ).order(Parent.arel_table[:aircall_id].not_eq(nil).desc, :aircall_id).first
        @errors << "AircallCall n'a pas pu être traité : Parent avec numéro #{external_number} n'existe pas ou a été supprimé" unless parent
        child_support_id = parent&.current_child&.child_support_id
      end
      admin_user = AdminUser.find_by(aircall_phone_number: aircall_phone_number)
      @errors << "AircallCall n'a pas pu être traité : AdminUser avec numéro #{aircall_phone_number} introuvable" unless admin_user
      return if @errors.any?

      tag_names = @payload['tags'].map { |tag| tag['name'] }.compact
      comments = @payload['comments'].map { |comment| comment['content'] }.compact
      @attributes =
        {
          aircall_id: @payload['id'],
          direction: @payload['direction'],
          parent_id: parent&.id,
          caller_id: admin_user.id,
          child_support_id: child_support_id.presence,
          missed_call_reason: @payload['missed_call_reason'],
          started_at: @payload['started_at'].present? ? Time.zone.at(@payload['started_at']) : nil,
          answered_at: @payload['answered_at'].present? ? Time.zone.at(@payload['answered_at']) : nil,
          ended_at: @payload['ended_at'].present? ? Time.zone.at(@payload['ended_at']) : nil,
          duration: @payload['duration'],
          asset_url: @payload['asset'],
          answered: @payload['answered_at'].present?,
          call_session: parent&.current_child&.group&.closest_call_session(Time.zone.at(@payload['started_at'])),
          tags: tag_names,
          notes: comments
        }
    end
  end
end
