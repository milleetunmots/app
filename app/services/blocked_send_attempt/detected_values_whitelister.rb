# Une relance vaut autorisation durable : les valeurs qui ont fait bloquer le
# message rejoignent la whitelist, sinon le même lien ou le même numéro serait
# re-bloqué au prochain envoi et il faudrait re-cliquer « Relancer » à chaque fois.
class BlockedSendAttempt::DetectedValuesWhitelister

  # Les mots-clés sont volontairement absents : ils viennent d'une liste noire
  # curée à la main (BlockedPattern), les whitelister reviendrait à la vider en
  # douce depuis un écran qui ne la nomme même pas.
  MATCH_TYPE_BY_KIND = { 'url' => 'exact', 'phone_number' => 'exact' }.freeze

  # Un envoi de masse produit une valeur détectée PAR DESTINATAIRE (cf.
  # UrlSendGuard#blocked_urls) : whitelister en bloc créerait des centaines de
  # lignes, chacune avec sa requête d'unicité, en plein cycle HTTP. Au-delà du
  # plafond on n'autorise rien et on le signale : c'est un pattern `domain`
  # saisi à la main qu'il faut, pas des centaines de patterns `exact`.
  MAX_VALUES = 25

  # Un lien personnalisé (UUID Calendly, query string de suivi) est unique par
  # destinataire : le whitelister en `exact` crée une ligne morte qui ne matchera
  # plus jamais. L'admin créera un pattern `domain` s'il veut autoriser la source.
  PER_RECIPIENT_URL_REGEX = /\h{8}-\h{4}-\h{4}-\h{4}-\h{12}|[?#]/

  def initialize(attempts)
    @attempts = Array(attempts)
  end

  # Renvoie les valeurs réellement ajoutées, pour que l'admin sache ce que sa
  # relance vient d'autoriser.
  def call
    candidates = @attempts.flat_map { |attempt| candidates_for(attempt) }.uniq
    return [] if candidates.empty?
    return [] if too_many?(candidates)

    candidates.filter_map { |kind, value| create_pattern(kind, value) }
  end

  private

  def candidates_for(attempt)
    return [] if MATCH_TYPE_BY_KIND[attempt.kind].blank?

    attempt.detected_values.filter_map do |value|
      whitelistable = whitelistable_value(attempt.kind, value)
      next if attempt.kind == 'url' && whitelistable.match?(PER_RECIPIENT_URL_REGEX)

      [attempt.kind, whitelistable]
    end
  end

  def too_many?(candidates)
    return false if candidates.size <= MAX_VALUES

    Rollbar.warning(
      'Relance : trop de valeurs détectées pour être whitelistées',
      count: candidates.size, attempt_ids: @attempts.map(&:id)
    )
    true
  end

  def create_pattern(kind, value)
    pattern = AllowedPattern.new(kind: kind, match_type: MATCH_TYPE_BY_KIND[kind], value: value)
    return pattern.value if pattern.save

    # Déjà whitelistée : c'est le résultat attendu, rien à signaler.
    return nil if pattern.errors.of_kind?(:value, :taken)

    # `save` et non `save!` : on est sur le chemin d'une relance réussie, le
    # message est déjà parti — une whitelist impossible ne doit pas la faire
    # échouer après coup.
    Rollbar.warning('Valeur détectée non whitelistée', kind: kind, value: value, errors: pattern.errors.full_messages)
    nil
  end

  # Les urls détectées sont souvent écrites sans schéma ("partenaire.fr/page") :
  # un pattern `exact` en exige un. Les numéros sont déjà sous leur forme
  # canonique, posée par PhoneNumberSendGuard.
  def whitelistable_value(kind, value)
    kind == 'url' ? AllowedPattern.canonicalize_url(value) : value
  end
end
