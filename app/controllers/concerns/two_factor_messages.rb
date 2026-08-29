# Messages partagés par l'interception du login et la page de saisie du code :
# les deux chemins appliquent les mêmes règles et doivent parler d'une seule voix.
module TwoFactorMessages
  MISSING_PHONE_NUMBER = "La double authentification est activée sur ce compte, mais aucun numéro de téléphone n'y est associé. Contactez un administrateur.".freeze
  RESEND_TOO_SOON = "Un code vient de vous être envoyé. Patientez une minute avant d'en demander un autre.".freeze
  SEND_FAILED = "L'envoi du code a échoué. Réessayez dans une minute avec le bouton « Renvoyer un code ».".freeze
end
