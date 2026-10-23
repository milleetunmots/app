module Metabase
  # Signe l'URL d'un dashboard Metabase embarqué en iframe (https://www.metabase.com/docs/latest/embedding/static-embedding).
  # Reçoit des valeurs, sans accès à la base : le choix de l'utilisateur et de ses paramètres revient à l'appelant.
  class GenerateEmbedUrlService

    # Seule la clef de signature est secrète : l'adresse du site et le dashboard sont des constantes.
    SITE_URL = 'https://metabase.1001mots.org'.freeze
    DASHBOARD_ID = 112
    TOKEN_VALIDITY = 10.minutes
    IFRAME_OPTIONS = 'bordered=true&titled=true'.freeze

    attr_reader :errors, :url

    def initialize(secret_key:, params:, site_url: SITE_URL, dashboard_id: DASHBOARD_ID, expires_in: TOKEN_VALIDITY)
      @site_url = site_url
      @secret_key = secret_key
      @dashboard_id = dashboard_id
      @params = params
      @expires_in = expires_in
      @errors = []
      @url = nil
    end

    def call
      return self unless configuration_valid?

      payload = { resource: { dashboard: dashboard_id }, params: @params, exp: @expires_in.from_now.to_i }
      token = JWT.encode(payload, @secret_key, 'HS256')
      @url = "#{@site_url.chomp('/')}/embed/dashboard/#{token}##{IFRAME_OPTIONS}"
      self
    end

    private

    def configuration_valid?
      missing = { site_url: @site_url, secret_key: @secret_key, dashboard_id: @dashboard_id }.select { |_, value| value.blank? }.keys
      if missing.any?
        @errors << { message: 'La configuration de Metabase est incomplète', context: { missing: missing } }
        return false
      end

      return true if dashboard_id&.positive?

      @errors << { message: 'L’identifiant du dashboard Metabase est invalide', context: { dashboard_id: @dashboard_id } }
      false
    end

    # nil si la valeur n'est pas un entier ("11.5", "abc")
    def dashboard_id
      Integer(@dashboard_id.to_s, 10, exception: false)
    end
  end
end
