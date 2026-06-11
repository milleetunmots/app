class SpotHit::RcsStatisticService

  URL = 'https://www.spot-hit.fr/api/campaign/rcs/statistic'.freeze

  attr_reader :errors

  def initialize(id:)
    @id = id
    @params = {
      'key' => ENV['SPOT_HIT_API_KEY'],
      'id' => @id,
    }
    @errors = []
  end

  def call
    get_campaign_statistic
    self
  end

  protected

  def get_campaign_statistic
    response = HTTP.get(
      URL,
      params: @params
    )
    # response = JSON.parse(response.to_s)
    # if response['success']
    #   create_events(response['campaign_id'])
    # else
    #   @errors << "Erreur lors de la programmation de la campagne : #{response['error']['message']}]"
    # end
  end
end
