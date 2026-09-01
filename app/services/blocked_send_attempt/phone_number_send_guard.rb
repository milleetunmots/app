# Détection des numéros de téléphone dans les messages sortants.
# Miroir de UrlSendGuard, whitelist comprise : tout numéro détecté qui n'est pas
# explicitement autorisé (AllowedPattern) est retenu, quel que soit son type —
# fixe, mobile, numéro vert ou surtaxé. Surveillance par défaut, blocage via
# PHONE_NUMBER_FILTER_BLOCKING_ENABLED.
#
# Les numéros courts (118 XYZ, 3BPQ) sont hors périmètre : le scan s'arrête aux
# numéros français à 10 chiffres.
class BlockedSendAttempt::PhoneNumberSendGuard < BlockedSendAttempt::BaseSendGuard

  # Numéros français à 10 chiffres, dans toutes les notations (+33, 0033, 0) et
  # avec les séparateurs habituels. Les lookarounds sur les chiffres évitent de
  # mordre dans une séquence plus longue : EAN à 13 chiffres d'un livre,
  # {PARENT_SECURITY_TOKEN} (hex, qui contient des suites de chiffres)…
  NATIONAL_PHONE_REGEX = %r{(?<!\d)(?:\+\s?33|0033|0)[\s.\-/]?[1-9](?:[\s.\-/]?\d){8}(?!\d)}

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
    scannable_text.scan(NATIONAL_PHONE_REGEX)
                  .map { |raw| PhoneNormalizationConcern.canonical(raw) }
                  .uniq
  end
end
