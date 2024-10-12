module Aircall
  class AircallApi

    BASE_URL = 'https://api.aircall.io'.freeze
    TOKEN_ID = ENV.fetch('AIRCALL_API_ID')
    TOKEN_PASSWORD = ENV.fetch('AIRCALL_API_TOKEN')
    CONTACT_BODY_PARAMS = %i[first_name last_name information].freeze
    CONTACT_PHONE_NUMBER_BODY_PARAMS = %i[label value].freeze

    attr_reader :request, :url

    def initialize(endpoint:, id: nil, phone_number_id: nil)
      @id = id
      @phone_number_id = phone_number_id
      @url = URI("#{BASE_URL}#{endpoint}#{"/#{@id.to_i}#{"/phone_details/#{@phone_number_id.to_i}" if @phone_number_id.present?}" if @id.present?}")
      @request = HTTP.basic_auth(user: TOKEN_ID, pass: TOKEN_PASSWORD)
    end
  end
end
