class BlockedSendAttempt::UrlSendGuard

  # Capture aussi les liens sans schéma (ex: "partenaire.fr/page") : un ou plusieurs
  # labels suivis d'un point puis un TLD alphabétique, pour éviter de matcher des
  # nombres décimaux (3.5) ou des numéros de version (v2.1).
  DOMAIN_REGEX = /(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,24}(?:\/\S*)?/i
  URL_REGEX = %r{https?://\S+|\b#{DOMAIN_REGEX}}i

  # Contournement fréquent : espacer un lien pour échapper aux filtres naïfs
  # (ex: "www blocked url . com"). On se limite à une liste de TLD connus pour ce
  # cas, faute de quoi n'importe quelle phrase se terminant par un point suivi d'un
  # mot court deviendrait un faux positif.
  SPACED_TLDS = %w[com fr net org io co be ch ca eu info app dev me biz uk de es it nl pt].freeze
  SPACED_DOMAIN_REGEX = /\b(?:[a-z0-9-]+\s+){1,4}\.\s*(?:#{SPACED_TLDS.join('|')})\b(?:\s*\.\s*(?:#{SPACED_TLDS.join('|')})\b)?/i

  def self.blocking_enabled?
    ENV['URL_FILTER_BLOCKING_ENABLED'].present?
  end

  def initialize(text, provider:, replay_params: {}, blocked_send_attempt_id: nil)
    @text = text
    @provider = provider
    @replay_params = replay_params
    @blocked_send_attempt_id = blocked_send_attempt_id
  end

  def blocked?
    blocked_urls.any?
  end

  # Tant que URL_FILTER_BLOCKING_ENABLED n'est pas activé, on se contente de tracer
  # la tentative (via register!) sans empêcher l'envoi réel.
  def block_send?
    blocked? && self.class.blocking_enabled?
  end

  def blocked_urls
    @blocked_urls ||= (scan_urls + scan_spaced_domains).uniq.reject { |url| AllowedPattern.url_allowed?(normalize_url(url)) }
  end

  def register!
    return if @blocked_send_attempt_id.present?

    BlockedSendAttempt.create!(
      provider: @provider,
      kind: 'url',
      detected_values: blocked_urls,
      message_body: @text,
      replay_params: @replay_params,
      status: block_send? ? 'pending' : 'not_blocked'
    )
  end

  private

  def scan_urls
    @text.to_s.scan(URL_REGEX)
  end

  def scan_spaced_domains
    @text.to_s.scan(SPACED_DOMAIN_REGEX).map { |match| match.gsub(/\s+/, '') }
  end

  def normalize_url(url)
    url.match?(%r{\Ahttps?://}i) ? url : "https://#{url}"
  end
end
