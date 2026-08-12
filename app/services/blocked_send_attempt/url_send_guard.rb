class BlockedSendAttempt::UrlSendGuard < BlockedSendAttempt::BaseSendGuard

  # Liste de TLD connus, partagée par les détections sans schéma et espacée : sans
  # elle, tout "mot.mot" (oubli d'espace après un point, très courant en SMS :
  # "ca va.Tu viens ?") deviendrait un faux positif.
  #
  # de / ca / me / es / it en sont volontairement absents : ce sont aussi des mots
  # français de début de phrase, et le point sans espace qui suit est fréquent en
  # SMS ("ca va.De plus…", "10h.Ca marche ?"). Les garder faisait bloquer des
  # messages légitimes. Un lien sur ces TLD reste détecté s'il porte son schéma
  # (https://…) ou le préfixe www.
  KNOWN_TLDS = %w[com fr net org io co be ch eu info app dev biz uk nl pt].freeze

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

  def self.kind
    'url'
  end

  def detected_values
    blocked_urls
  end

  # Les patterns sont chargés une seule fois : un envoi de masse avec une variable
  # {URL} ou {CALLx_CALENDLY_LINK} par destinataire produit autant d'URLs
  # distinctes que de parents, et rechargeait la table pour chacune.
  def blocked_urls
    @blocked_urls ||=
      begin
        urls = (scan_urls + scan_spaced_domains).uniq
        if urls.empty?
          []
        else
          patterns = AllowedPattern.where(kind: 'url').to_a
          urls.reject { |url| AllowedPattern.url_allowed?(normalize_url(url), patterns: patterns) }
        end
      end
  end

  private

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
