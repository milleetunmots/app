class SpotHit::DeleteRcsModelService

  include JsonResponseConcern

  URL = 'https://www.spot-hit.fr/api/rcs/model/delete'.freeze

  attr_reader :errors

  def initialize(rcs_media_id:)
    @errors = []
    @rcs_media_id = rcs_media_id
  end

  def call
    return self if Rails.env.development? || ENV['SPOT_HIT_SAFEGUARD'].present?

    response = HTTP.post(
      URL,
      form: {
        'key' => ENV['SPOT_HIT_API_KEY'],
        'id' => @rcs_media_id
      }
    )
    parsed_response = parse_json_response(response)
    success = parsed_response.is_a?(Hash) && parsed_response['success'] == true
    @errors << "Erreur lors de la suppression du modèle RCS: #{@rcs_media_id} — #{json_error_message(response, parsed_response)}" unless success
    self
  end
end
