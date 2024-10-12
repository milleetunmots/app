module Aircall
  class DeleteContactService

    attr_reader :errors

    def initialize(id: nil, endpoint: '/v1/contacts')
      @id = id
      @endpoint = endpoint
      @errors = []
      @contacts = Aircall::RetrieveContactService.new(id: @id).call.contacts
    end

    def call
      if @id
        delete_contact
      else
        @contacts.each do |contact|
          @id = contact['id']
          delete_contact
        end
      end
      self
    end

    private

    def delete_contact
      return unless @id

      @aircall_connexion = Aircall::AircallApi.new(endpoint: @endpoint, id: @id)
      sleep(1)
      puts "delete #{@aircall_connexion.url}"
      @response = @aircall_connexion.request.delete(@aircall_connexion.url)
      @errors << { message: "La création a échoué : #{@response.status.reason}", status: @response.status.to_i } unless @response.status.no_content?
    end
  end
end
