module SpotHit
  class GetCreditsService
    attr_reader :errors, :premium, :mms

    def initialize
      @uri = URI("https://www.spot-hit.fr/api/credits")
      @form = { "key" => ENV["SPOT_HIT_API_KEY"] }

      @errors = []
      @premium = 0
      @mms = 0
    end

    def call
      response = HTTP.post(@uri, form: @form)
      credits = JSON.parse(response.body.to_s)
      if credits.key?("erreurs")
        @errors << "Erreur lors du check du nombre de crédit spot-hit. [Réponse SPOT_HIT API #{response.body.to_s}]"
      else
        @premium = credits["premium"].to_i
        @mms = credits["mms"].to_i
      end

      self
    end
  end
end
