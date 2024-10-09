require 'net/http'
require 'json'

class Aircall::ConnexionService
  BASE_URL = "https://api.aircall.io"
  USER_ID = ENV['AIRCALL_API_ID']
  USER_PASSWORD = ENV['AIRCALL_API_TOKEN']

  def initialize(endpoint)
    @url = URI("#{BASE_URL}/#{endpoint}")
  end

  def get
    request = Net::HTTP::Get.new(@url)
    request.basic_auth(USER_ID, USER_PASSWORD)

    handle_request(request)
  end

  def post(params = {})
    request = Net::HTTP::Post.new(@url, { 'Content-Type' => 'application/json' })
    request.basic_auth(USER_ID, USER_PASSWORD)
    request.body = params.to_json

    handle_request(request)
  end

  private

  def handle_request(request)
    response = Net::HTTP.start(@url.hostname, @url.port, use_ssl: @url.scheme == 'https') do |http|
      http.request(request)
    end

    parse_response(response)
  end

  def parse_response(response)
    if response.instance_of?(Net::HTTPOK)
      JSON.parse(response.body)
    else
      { error: "HTTP error: #{response.message}", status: response.code.to_i }
    end
  end
end
