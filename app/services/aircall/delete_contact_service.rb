module Aircall
  class DeleteContactService < Aircall::ApiBase

    attr_reader :errors, :deleted_contact_ids

    def initialize(contact_id: nil, delete_all: false)
      # CAREFUL : all contacts will be deleted if delete_all is true and contact_id is nil
      @contact_id = contact_id # must be aircall's contact id
      @delete_all_contacts = delete_all
      @deleted_contact_ids = []
      @errors = []
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

      if @contact_id
        delete_contact
      elsif @delete_all_contacts
        contacts_service = Aircall::RetrieveContactService.new.call
        @errors << {
          message: "La suppression a échoué : erreur de récupération des contacts",
          status: 422
        } and return self if contacts_service.errors.any?

        contacts_service.contacts.each do |contact|
          @contact_id = contact['id']
          delete_contact
        end
      end
      self
    end

    private

    def delete_contact
      return unless @contact_id

      sleep(1)
      url = "#{BASE_URL}#{CONTACTS_ENDPOINT}/#{@contact_id}"
      response = http_client_with_auth.delete(url)
      if response.status.no_content?
        @deleted_contact_ids << @contact_id
      else
        @errors << { message: "La suppression a échoué : #{response.status.reason}", status: response.status.to_i }
      end
    end
  end
end
