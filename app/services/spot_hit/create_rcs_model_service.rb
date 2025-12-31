class SpotHit::CreateRcsModelService

  URL = URI('https://www.spot-hit.fr/api/rcs/model/create')

  attr_reader :errors

  def initialize(body:)
    @body = body
    @errors = []
    @model_content = {
      "content" => {
        "card" => {
          "title" => "Card - Title",
          "text" => "Card - Texte",
          "mediaType" => "image",
          "buttons" => [],
          "suggestions" => [],
          "options" => []
        },
        "property" => {
          "stop" => true
        }
      }
    }
    @form_data = {
      'key' => ENV['SPOT_HIT_API_KEY'],
      'model' => @model_content.to_json
    }
  end

  def call
    create_rcs
    self
  end

  protected

  def create_rcs
    response = HTTP.post(URL, form: { 'key' => ENV['SPOT_HIT_API_KEY'] }, json: @model_content)
    p JSON.parse(response.body.to_s)
  end
end

