# Réponse à « Enregistrer les choix de livres ? », posée avant chaque export logistique manuel.
# Elle est obligatoire : sans réponse, l'export est refusé (une URL tapée ne doit rien figer).
module FreezeBooksChoice
  QUESTION = 'Enregistrer les choix de livres ?'.freeze
  MISSING_ANSWER = 'Indiquez si les choix de livres doivent être enregistrés'.freeze
  ANSWERS = { 'true' => true, 'false' => false }.freeze

  # nil quand l'utilisateur n'a pas répondu
  def self.parse(value)
    ANSWERS[value]
  end
end
