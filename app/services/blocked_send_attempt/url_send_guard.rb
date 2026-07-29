class BlockedSendAttempt::UrlSendGuard

  # Liste de TLD connus, partagée par les détections sans schéma et espacée : sans
  # elle, tout "mot.mot" (oubli d'espace après un point, très courant en SMS :
  # "ca va.Tu viens ?") deviendrait un faux positif.
  KNOWN_TLDS = %w[com fr net org io co be ch ca eu info app dev me biz uk de es it nl pt].freeze

  # Capture aussi les liens sans schéma (ex: "partenaire.fr/page") : TLD connu
  # obligatoire, sauf préfixe www. qui suffit à identifier un lien. Le lookahead
  # évite de matcher un TLD suivi de lettres ("bon.commencez").
  DOMAIN_LABELS = /(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+/i
  DOMAIN_REGEX = /(?:www\.#{DOMAIN_LABELS}[a-z]{2,24}|#{DOMAIN_LABELS}(?:#{KNOWN_TLDS.join('|')}))(?![a-z0-9-])(?:\/\S*)?/i
  URL_REGEX = %r{https?://\S+|\b#{DOMAIN_REGEX}}i

  # Contournement fréquent : espacer un lien pour échapper aux filtres naïfs
  # (ex: "www blocked url . com").
  SPACED_DOMAIN_REGEX = /\b(?:[a-z0-9-]+\s+){1,4}\.\s*(?:#{KNOWN_TLDS.join('|')})\b(?:\s*\.\s*(?:#{KNOWN_TLDS.join('|')})\b)?/i

  # https?://\S+ capture la ponctuation de fin de phrase collée à l'URL
  # ("https://exemple.fr/page.") : sans strip, le match_type exact échoue.
  TRAILING_PUNCTUATION_REGEX = /[.,;:!?)\]}]+\z/

  def self.blocking_enabled?
    ENV['URL_FILTER_BLOCKING_ENABLED'].present?
  end

  # extra_texts : contenus scannés en plus du message mais non stockés comme
  # message_body — typiquement les valeurs des variables destinataires SpotHit
  # ({URL}, {CALLx_CALENDLY_LINK}…), encore sous forme de placeholders dans text.
  def initialize(text, provider:, extra_texts: [], replay_params: {}, blocked_send_attempt_id: nil)
    @text = text
    @extra_texts = extra_texts
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

    # Aircall::SendMessageJob (retry: 10) repasse ici à chaque tentative après un
    # échec API : on retrouve la tentative identique déjà tracée plutôt que d'en
    # créer une par retry.
    existing = BlockedSendAttempt
               .where(status: %w[pending not_blocked], provider: @provider, kind: 'url', message_body: @text)
               .find_by(replay_params: @replay_params)
    return existing if existing

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

  def scannable_text
    @scannable_text ||= ([@text] + Array(@extra_texts)).map(&:to_s).join("\n")
  end

  def scan_urls
    scannable_text.scan(URL_REGEX).map { |url| url.sub(TRAILING_PUNCTUATION_REGEX, '') }
  end

  def scan_spaced_domains
    scannable_text.scan(SPACED_DOMAIN_REGEX).map { |match| match.gsub(/\s+/, '') }
  end

  def normalize_url(url)
    url.match?(%r{\Ahttps?://}i) ? url : "https://#{url}"
  end
end
