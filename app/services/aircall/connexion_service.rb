require 'net/http'
require 'json'

class Aircall::ConnexionService
  BASE_URL = "https://api.aircall.io"
  TOKEN_ID = ENV['AIRCALL_API_ID']
  TOKEN_PASSWORD = ENV['AIRCALL_API_TOKEN']

  attr_reader :errors, :response

  def initialize(endpoint)
    @url = URI("#{BASE_URL}/#{endpoint}")
    @errors = []
  end

  def get
    handle_request
    self
  end

  # def post(params = {})
  #   request = Net::HTTP::Post.new(@url, { 'Content-Type' => 'application/json' })
  #   request.basic_auth(TOKEN_ID, TOKEN_PASSWORD)
  #   request.body = params.to_json

  #   handle_request(request)
  # end

  private

  def handle_request
    response = HTTP.basic_auth(user: TOKEN_ID, pass: TOKEN_PASSWORD).get(@url)

    parse_response(response)
  end

  def parse_response(response)
    if response.status.success?
      @response = JSON.parse(response.body)
    else
      @errors << { message: "L'appel api a échoué : #{response.status.reason}", status: response.status.to_i }
    end
  end
end
