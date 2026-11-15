# One-shot, à exécuter en production (les valeurs de l'ENV sont figées dans les textes).
namespace :text_messages_bundles do
  desc 'Create one TextMessagesBundle per automatic message, from the texts currently in the code'
  task create_automatic_messages: :environment do
    instagram_invitation = 'etrouvez sur Instagram nos idées d’activités et nos conseils pour occuper {PRENOM_ENFANT}, abonnez-vous ! ' \
                           "#{ENV['INSTAGRAM_LINK']}"

    messages = {
      "Annonce d'arrêt (2 KO)" => ChildSupport::ChildrenDisengagementService::MESSAGE,
      "Annonce d'arrêt (2 KO) — fratrie" => ChildSupport::ChildrenDisengagementService::MESSAGE.gsub('{PRENOM_ENFANT}', 'vos enfants'),
      'Après 1er KO · Appel 0' => Parent::SendDisengagementWarningAfterCallsService::MESSAGE[0],
      'Après 1er KO · Appel 1' => Parent::SendDisengagementWarningAfterCallsService::MESSAGE[1],
      'Après 1er KO · Appel 2' => Parent::SendDisengagementWarningAfterCallsService::MESSAGE[2],
      'Arrêt · Famille pose problème / Inscrite sans accord / Ne veut pas du programme / Pratiques très avancées' =>
        ChildSupport::CallerStopSupportService::PROGRAM_TERMINATION_MESSAGE,
      'Arrêt · Pas assez francophone' => ChildSupport::CallerStopSupportService::LANGUAGE_BARRIER_TERMINATION_MESSAGE,
      'Arrêt · Professionnel·le de santé qui teste' => ChildSupport::CallerStopSupportService::PARTNER_REFERRAL_REQUIRED_MESSAGE,
      "Bienvenue (hors période d'été)" =>
        "Bonjour, merci pour votre inscription à l'accompagnement de l'association 1001mots. Bienvenue, ça va bientôt démarrer !\nL'équipe 1001mots",
      "Bienvenue (période d'été)" =>
        "Bonjour, merci pour votre inscription à l'accompagnement de l'association 1001mots ! Pendant l'été, nous faisons une petite pause dans " \
        "les accompagnements. Vous allez recevoir les premiers livres et conseils à la rentrée. A bientôt !\nL'équipe 1001mots",
      'Confirmation de RDV' => Calendly::ProcessInviteeCreatedService::SCHEDULED_CALL_CONFIRMATION_MESSAGE
               .gsub('{SCHEDULED_AT_HOUR}', '{RDV_CALENDLY_SCHEDULED_AT_HOUR}')
               .gsub('{CANCEL_URL}', '{RDV_CALENDLY_CANCEL_URL}'),
      "Demande de vérification d'adresse (PND)" =>
        "#{Parent::CheckAddressService::MESSAGE} https://form.typeform.com/to/#{ENV['UPDATING_ADDRESS_TYPEFORM_ID']}#st=xxxxx",
      'Démarrage tardif' => Child::AddToGroupService::LATE_SUPPORT_WARNING_MESSAGE,
      "Fin d'accompagnement, étude eval" => Child::SendEvalMessageService::EVAL_MESSAGE.gsub('{typeform_link}', '{LIEN_ETUDE_EVAL}'),
      'Fin du programme' => Group::StopSupportService::END_OF_SUPPORT_SMS,
      "Fin du programme (l'enfant a 3 ans)" => Group::StopSupportService::MORE_THAN_THIRTY_SIX_SMS,
      'Garder le lien sur Instagram' => Group::StopSupportService::INSTAGRAM_SMS,
      'Inscription confirmée (eval25)' =>
        "1001mots : Bonjour, votre inscription au programme 1001mots est confirmée. L'accompagnement va bientôt démarrer. A bientôt !",
      'Invitation à choisir le prochain thème' =>
        '1001mots : Cliquez sur le lien pour choisir votre prochain thème pour {PRENOM_ENFANT} et recevoir un nouveau livre. ' \
        'Attention dans {DELAI_CHOIX_THEME}, nous choisirons à votre place ! {LIEN_CHOIX_THEME}',
      'Invitation à remplir le questionnaire' =>
        "Bonjour,\nMerci pour votre inscription à l’accompagnement de l’association 1001mots !\nPour que les livres et les conseils soient " \
        'adaptés à {PRENOMS_ENFANTS}, vous pouvez remplir ce rapide questionnaire ? (3 minutes) Merci beaucoup ! ' \
        "{LIEN_QUESTIONNAIRE}\nL’équipe 1001mots",
      'Invitation à suivre Instagram' => "1001mots : En attendant que votre accompagnement 1001mots commence, r#{instagram_invitation}",
      'Invitation à suivre Instagram (CAF)' => "1001mots : R#{instagram_invitation}",
      'Message de continuation' =>
        'Bonjour ! Ca fait 4 mois que je vous envoie des SMS pour votre enfant. Bravo pour tout ce que vous faites pour lui :) ' \
        'Voulez vous continuer à recevoir ces SMS et livres ? Cliquez sur le lien ci-dessous et répondez OUI ! Ca reprendra prochainement ! ' \
        'Je vous souhaite de beaux moments avec vos enfants :) {QUIT_LINK}',
      'Message de non-accompagnement' =>
        "1001mots : Bonjour ! Suite à votre demande d'inscription, nous regrettons de ne pas pouvoir accompagner votre enfant. Les places " \
        'sont limitées et attribuées selon des critères spécifiques. Toutefois, nous avons préparé un ensemble de conseils qui peuvent aider ' \
        'votre enfant à développer son langage. Vous les trouverez ici : {URL}',
      'Messages aux familles bilingues (J0)' => Group::ProgramSmsToBilingualsService::FIRST_MESSAGE,
      'Messages aux familles bilingues (J+7)' => Group::ProgramSmsToBilingualsService::SECOND_MESSAGE,
      'Messages aux familles bilingues (J+14)' => Group::ProgramSmsToBilingualsService::THIRD_MESSAGE,
      'Numéro qui ne reçoit pas de SMS' =>
        "#{Event::SendMessageToParentResponseService::MESSAGE} {PRENOM_ACCOMPAGNANTE} au {NUMERO_AIRCALL_ACCOMPAGNANTE}. Merci!",
      "Rappel d'inscription CAF (v1)" => Parent::ProgramCafSubscriptionReminderService::MESSAGE_V1,
      "Rappel d'inscription CAF (v2)" => Parent::ProgramCafSubscriptionReminderService::MESSAGE_V2,
      'Rappel de petite mission — appel 0' => ChildSupport::SendCall0GoalsReminderMessagesService::CALL_GOALS_REMINDER_MESSAGE
               .gsub('{call_goals}', '{PETITE_MISSION}').gsub('{typeform_link}', '{LIEN_SUIVI_PETITE_MISSION}'),
      'Rappel de petite mission — appel 3' => ChildSupport::SendCallGoalsMessagesService::CALL_GOALS_REMINDER_MESSAGE
               .gsub('À bientôt', 'Bonne journée').gsub('{call_goals}', '{PETITE_MISSION}').gsub('{typeform_link}', '{LIEN_SUIVI_PETITE_MISSION}'),
      'Rappel de RDV — jour J (~2h avant)' => Parent::SendSameDayScheduledCallReminderService::SCHEDULED_CALL_REMINDER_SAME_DAY,
      'Rappel de RDV — la veille (J-1)' => Parent::SendNextDayScheduledCallReminderService::SCHEDULED_CALL_REMINDER_DAY_BEFORE,
      'Relance de dernière chance' =>
        '1001mots : dernière chance pour choisir votre prochain thème pour que {PRENOM_ENFANT} reçoive son prochain livre ! {LIEN_CHOIX_THEME}',
      'Relance du choix de thème' =>
        '1001mots : pour recevoir le prochain livre de 1001mots pour {PRENOM_ENFANT}, n\'oubliez pas de choisir votre thème en cliquant sur ' \
        'ce lien avant minuit : {LIEN_CHOIX_THEME}',
      'Repêchage après annulation de RDV' => Calendly::ProcessInviteeCanceledService::REBOOKING_MESSAGE,
      "Suggestion d'un lieu d'accueil enfants-parents" => Place::SendMessageToParentsNearLaepService::MESSAGE,
      "Vérification de l'adresse" =>
        "#{Parent::ProgramSmsToVerifyAddressService::MESSAGE.gsub('{ADDRESS}', "\n{PARENT_ADDRESS}\n")} " \
        "https://form.typeform.com/to/#{ENV['UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID']}#st=xxxxx",
      "Vérification de l'adresse pour le livre offert par un partenaire" =>
        "1001mots : Bonjour,\nVotre accompagnement avec 1001mots est fini ou sera bientôt fini. Mais un de nos partenaires tient à vous offrir " \
        "un dernier livre, récolté auprès de parents d'enfants plus grands, qui ont eu envie de partager les livres qu'ils ont aimés à l'âge " \
        "de {PRENOM_ENFANT}.\nNous allons l'envoyer à l'adresse suivante :\n{PARENT_ADDRESS}\nSi l'adresse postale ou le nom sur la boîte " \
        'aux lettres ne sont pas bons, merci de les modifier ici : https://form.typeform.com/to/IDpRjIqI#st=xxxxx'
    }

    created = []
    skipped = []
    messages.each do |name, body|
      if Media::TextMessagesBundle.exists?(name: name)
        skipped << name
        next
      end

      bundle = Media::TextMessagesBundle.create!(name: name, body1: body.strip, tag_list: ['message automatique'])
      created << name
      puts "Créé : #{name} (##{bundle.id})"
    end

    skipped.each { |name| puts "Déjà présent, ignoré : #{name}" }
    puts "#{created.size} trio(s) créé(s), #{skipped.size} ignoré(s) sur #{messages.size}."
  end
end
