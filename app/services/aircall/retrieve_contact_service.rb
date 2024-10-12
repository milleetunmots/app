module Aircall
  class RetrieveContactService

    attr_reader :errors, :contacts

    def initialize(id: nil, endpoint: '/v1/contacts')
      @id = id
      @endpoint = endpoint
      @errors = []
    end

    def call
      @aircall_connexion = Aircall::AircallApi.new(endpoint: @endpoint, id: @id)
      sleep(1)
      puts "retrieve #{@aircall_connexion.url}"

      @response = @aircall_connexion.request.get(@aircall_connexion.url)
      if @response.status.success?
        body = JSON.parse(@response.body)
        @meta = body['meta']
        @contacts = body['contacts'] || body['contact']
        retrieve_next_contacts
      else
        @errors << { message: "La création a échoué : #{@response.status.reason}", status: @response.status.to_i }
      end
      self
    end

    private

    def retrieve_next_contacts
      return if @meta.nil? || @meta['next_page_link'].nil?

      next_endpoint = @meta['next_page_link'].split('api.aircall.io').second
      next_contact_retrieved = Aircall::RetrieveContactService.new(endpoint: next_endpoint).call.contacts
      @contacts.concat(next_contact_retrieved).uniq!
    end
  end
end
