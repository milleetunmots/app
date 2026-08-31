# Détection des numéros surtaxés dans les messages sortants.
# Miroir de UrlSendGuard : surveillance par défaut, blocage via
# PHONE_NUMBER_FILTER_BLOCKING_ENABLED.
#
# Contrairement aux URLs, le périmètre est volontairement restreint aux numéros
# à valeur ajoutée : les messages automatiques contiennent légitimement des
# numéros ({NUMERO_AIRCALL_ACCOMPAGNANTE}, {NUMERO_PARENT}), et un fixe ou un
# mobile n'est donc ni bloqué ni tracé.
#
# Les numéros courts (118 XYZ, 3BPQ) sont eux aussi hors périmètre : Phonelib ne
# les type que si `parse_special` est activé — un réglage global qui changerait
# la validité des numéros partout ailleurs — et sa métadonnée y classe à tort en
# premium_rate des numéros d'aide gratuits (3919, 3977, 3237).
class BlockedSendAttempt::PhoneNumberSendGuard < BlockedSendAttempt::BaseSendGuard

  # Numéros français à 10 chiffres, dans toutes les notations (+33, 0033, 0) et
  # avec les séparateurs habituels. Les lookarounds sur les chiffres évitent de
  # mordre dans une séquence plus longue : EAN à 13 chiffres d'un livre,
  # {PARENT_SECURITY_TOKEN} (hex, qui contient des suites de chiffres)…
  NATIONAL_PHONE_REGEX = %r{(?<!\d)(?:\+\s?33|0033|0)[\s.\-/]?[1-9](?:[\s.\-/]?\d){8}(?!\d)}

  # Les numéros courts (118 XYZ, 3BPQ) sont hors périmètre : Phonelib ne les
  # type que si `parse_special` est activé — un réglage global qui changerait la
  # validité des numéros partout ailleurs — et sa métadonnée y classe à tort en
  # premium_rate des numéros d'aide gratuits (3919, 3977, 3237).

  # Catégories libphonenumber facturées au-delà d'un appel ordinaire. Elles
  # couvrent l'ensemble du plan de numérotation français à valeur ajoutée, sans
  # liste de préfixes à maintenir :
  #   :uan          → 0806-0809, « numéros gris » (service gratuit + prix appel)
  #   :shared_cost  → 0810 0811 0820 0821 0825 0826 0840 0842 0844 0884
  #   :premium_rate → 0812-0819, 0822-0839, 0850-0869, 0880-0899
  # Les fixes (:fixed_line), mobiles (:mobile) et numéros verts (:toll_free,
  # 0800-0805) en sont exclus.
  PREMIUM_TYPES = %i[premium_rate shared_cost uan].freeze

  def self.blocking_enabled?
    ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'].present?
  end

  def self.kind
    'phone_number'
  end

  def detected_values
    blocked_phone_numbers
  end

  # Le typage Phonelib est appliqué avant la whitelist : un envoi de masse avec
  # une variable {NUMERO_AIRCALL_ACCOMPAGNANTE} produit un candidat par
  # destinataire, mais ce sont des mobiles, écartés sans aucune requête.
  def blocked_phone_numbers
    @blocked_phone_numbers ||= scan_candidates
                               .select { |number| PREMIUM_TYPES.include?(Phonelib.parse(number).type) }
                               .reject { |number| AllowedPattern.phone_allowed?(number) }
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
