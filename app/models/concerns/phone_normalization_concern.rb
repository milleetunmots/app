# Forme canonique d'un numéro, partagée par tout ce qui doit comparer des
# numéros entre eux : patterns bloqués/autorisés (à la sauvegarde), numéros
# Aircall, et numéros scannés dans un message (au moment du contrôle).
#
# Phonelib ramène toutes les notations d'un numéro à la même forme nationale
# ("+33 8 90 12 34 56" comme "0033890123456" donnent 0890123456), et laisse
# intacts les préfixes de tranche ('089') comme les numéros courts ('118') :
# il ne sait pas les parser, et `national` retombe alors sur l'entrée nettoyée.
# C'est ce qui permet aux deux de coexister dans le même espace de comparaison.
module PhoneNormalizationConcern
  def self.canonical(value)
    Phonelib.parse(value).national.to_s.gsub(/\D/, '')
  end
end
