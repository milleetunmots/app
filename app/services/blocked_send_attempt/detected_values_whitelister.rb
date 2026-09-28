# Une relance vaut autorisation durable : les valeurs qui ont fait bloquer le
# message rejoignent la whitelist, sinon le même lien ou le même numéro serait
# re-bloqué au prochain envoi et il faudrait re-cliquer « Relancer » à chaque fois.
class BlockedSendAttempt::DetectedValuesWhitelister

  # Les mots-clés sont volontairement absents : ils viennent d'une liste noire
  # curée à la main (BlockedPattern), les whitelister reviendrait à la vider en
  # douce depuis un écran qui ne la nomme même pas.
  MATCH_TYPE_BY_KIND = { 'url' => 'exact', 'phone_number' => 'exact' }.freeze

  def initialize(attempts)
    @attempts = Array(attempts)
  end

  # Renvoie les valeurs réellement ajoutées, pour que l'admin sache ce que sa
  # relance vient d'autoriser.
  def call
    @attempts.flat_map { |attempt| whitelist_attempt(attempt) }.uniq
  end

  private

  def whitelist_attempt(attempt)
    match_type = MATCH_TYPE_BY_KIND[attempt.kind]
    return [] if match_type.blank?

    attempt.detected_values.filter_map { |value| create_pattern(attempt.kind, match_type, value) }
  end

  def create_pattern(kind, match_type, value)
    pattern = AllowedPattern.new(kind: kind, match_type: match_type, value: whitelistable_value(kind, value))
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
