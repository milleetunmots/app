# Détection des numéros de téléphone dans les messages sortants.
# Miroir de UrlSendGuard, whitelist comprise : tout numéro détecté qui n'est pas
# explicitement autorisé (AllowedPattern) est retenu, quel que soit son type —
# fixe, mobile, numéro vert ou surtaxé. Surveillance par défaut, blocage via
# PHONE_NUMBER_FILTER_BLOCKING_ENABLED.
class BlockedSendAttempt::PhoneNumberSendGuard < BlockedSendAttempt::BaseSendGuard

  # On extrait largement les graphies humaines (préfixe international,
  # parenthèses, séparateurs), puis Phonelib décide si le candidat est réellement
  # un numéro. Les bornes alphanumériques empêchent de scanner une sous-chaîne de
  # token hexadécimal comme PARENT_SECURITY_TOKEN.
  PHONE_CANDIDATE_REGEX = %r{(?<![[:alnum:]])(?:\+|00|0)[[:blank:](]*\d(?:[\d[:blank:]./()-]*\d)?(?![[:alnum:]])}

  # Phonelib ne valide pas les numéros courts. On limite volontairement ce scan
  # aux formats de services français : 10XY, 3BPQ et renseignements 118 XYZ.
  SHORT_PHONE_REGEX = %r{(?<![[:alnum:]])(?:10\d{2}|3\d{3}|118[[:blank:]./-]?\d{3})(?![[:alnum:]])}

  # Un ISBN-10 peut être un numéro français parfaitement valide après retrait de
  # ses tirets. Le libellé adjacent est le seul moyen fiable de le distinguer.
  IDENTIFIER_LABEL_REGEX = /(?:isbn(?:-1[03])?|ean)\s*[:#]?\s*\z/i
  IDENTIFIER_CONTEXT_LENGTH = 16
  PHONE_DIGIT_COUNT = (7..15)

  def self.blocking_enabled?
    ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'].present?
  end

  def self.kind
    'phone_number'
  end

  def detected_values
    blocked_phone_numbers
  end

  # Les numéros autorisés sont chargés une seule fois : un envoi de masse avec une
  # variable {NUMERO_AIRCALL_ACCOMPAGNANTE} ou {NUMERO_PARENT} produit un candidat
  # par destinataire, et rechargeait whitelist et numéros Aircall pour chacun.
  def blocked_phone_numbers
    @blocked_phone_numbers ||=
      begin
        numbers = scan_candidates
        if numbers.empty?
          []
        else
          allowed_numbers = AllowedPattern.allowed_phone_numbers
          numbers.reject { |number| AllowedPattern.phone_allowed?(number, allowed_numbers: allowed_numbers) }
        end
      end
  end

  private

  # On retient la forme canonique et non la graphie d'origine : un même numéro
  # écrit de plusieurs façons dans un message ne doit produire qu'une seule
  # valeur détectée.
  def scan_candidates
    (scan_long_phone_numbers + scan_short_phone_numbers).uniq
  end

  def scan_long_phone_numbers
    matches_for(PHONE_CANDIDATE_REGEX).filter_map do |raw, offset|
      next if identifier_context?(offset)
      next unless PHONE_DIGIT_COUNT.cover?(raw.count('0-9'))
      next unless Phonelib.parse(raw).valid?

      PhoneNormalizationConcern.canonical(raw)
    end
  end

  def scan_short_phone_numbers
    matches_for(SHORT_PHONE_REGEX).map do |raw, _offset|
      PhoneNormalizationConcern.canonical(raw)
    end
  end

  # String#scan ne fournit pas directement les offsets, nécessaires pour lire le
  # contexte précédant un ISBN/EAN. On capture le MatchData avant que Phonelib
  # n'exécute ses propres expressions régulières.
  def matches_for(regex)
    scannable_text.to_enum(:scan, regex).map do
      match = Regexp.last_match
      [match[0].strip, match.begin(0)]
    end
  end

  def identifier_context?(offset)
    from = [offset - IDENTIFIER_CONTEXT_LENGTH, 0].max
    scannable_text[from...offset].match?(IDENTIFIER_LABEL_REGEX)
  end
end
