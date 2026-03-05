class SpotHit::DeleteRcsModelService

  URL = 'https://www.spot-hit.fr/api/rcs/model/delete'.freeze

  attr_reader :errors

  def initialize(rcs_media_id:)
    @errors = []
    @rcs_media_id = rcs_media_id
  end

  def call
    response = HTTP.post(
      URL,
      form: {
        'key' => ENV['SPOT_HIT_API_KEY'],
        'id' => @rcs_media_id
      }
    )
    parsed_response = JSON.parse(response.body.to_s)
    @errors << "Erreur lors de la suppression du modèle RCS: #{@rcs_media_id}" if parsed_response['success'] != true
    self
  end
end
