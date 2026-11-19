# One-shot, à exécuter en production (les valeurs de l'ENV sont figées dans les textes).
namespace :text_messages_bundles do
  desc 'Create one TextMessagesBundle per automatic message, from the texts currently in the code'
  task create_automatic_messages: :environment do
    instagram_invitation = 'etrouvez sur Instagram nos idées d’activités et nos conseils pour occuper {PRENOM_ENFANT}, abonnez-vous ! ' \
                           "#{ENV['INSTAGRAM_LINK']}"

    texts = {
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
      # Recopié : charger Child::SendEvalMessageService exige les identifiants Google (GOOGLE_CREADENTIALS_JSON).
      "Fin d'accompagnement, étude eval" =>
        "1001mots : L'accompagnement de {PRENOM_ENFANT} est maintenant terminé. Vous avez AIMÉ les livres et les conseils ? Alors vous " \
        'pouvez nous AIDER à votre tour : PARTICIPEZ à notre grande ETUDE sur le langage des bébés ! Cliquez ici pour en savoir plus : ' \
        '{LIEN_ETUDE_EVAL}',
      'Fin du programme' =>
        "C'est maintenant la fin des SMS et des livres 1001mots pour {PRENOM_ENFANT}. Nous espérons que ça vous a apporté des idées et de " \
        'la confiance en vous en tant que parent ! Pour retrouver plein d’autres conseils RDV sur cette page {URL}. Je vous souhaite une ' \
        'bonne continuation et plein de beaux moments avec votre enfant !',
      "Fin du programme (l'enfant a 3 ans)" =>
        "C'est la fin des SMS et des livres 1001mots pour votre enfant de 3 ans. Nous espérons que ça vous a apporté des idées et de la " \
        'confiance en vous en tant que parent ! Pour retrouver plein d’autres conseils RDV sur cette page {URL}. Je vous souhaite une bonne ' \
        'continuation et plein de beaux moments avec votre enfant !',
      'Garder le lien sur Instagram' =>
        "1001mots vous manque ? Suivez-nous sur Instagram pour plus d’idées d’activités et de conseils : #{ENV['INSTAGRAM_LINK']}",
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
      'Message de non-accompagnement' =>
        "1001mots : Bonjour ! Suite à votre demande d'inscription, nous regrettons de ne pas pouvoir accompagner votre enfant. Les places " \
        'sont limitées et attribuées selon des critères spécifiques. Toutefois, nous avons préparé un ensemble de conseils qui peuvent aider ' \
        'votre enfant à développer son langage. Vous les trouverez ici : {URL}',
      'Messages aux familles bilingues (J0)' =>
        "Si vous parlez une autre langue que le français à la maison, c'est une chance pour votre enfant ! Sentez-vous libre de parler " \
        "dans VOTRE LANGUE si vous êtes plus à l'aise, l'important c'est de lui parler souvent !",
      'Messages aux familles bilingues (J+7)' =>
        "Un enfant qui entend d'autres langues que le français à la maison n'aura pas de retard de langage et apprendra le français le " \
        'moment venu. Il peut mélanger plusieurs langues mais ne les confond pas. Je vous en dis plus dans cette vidéo ! {URL}',
      'Messages aux familles bilingues (J+14)' =>
        "La maman d'Hanaé, qui parle le créole avec sa fille, témoigne : \"N'hésitez pas à partager ce que vous êtes, et ce que ses " \
        'grands-parents sont, vos valeurs, en parlant vos langues maternelles, pour savoir d\'où l\'on vient et pour pouvoir avancer au ' \
        'mieux dans le futur." Et chez vous, quelle langue parlez-vous avec votre enfant ?',
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

    keys = {
      "Annonce d'arrêt (2 KO)" => 'annonce_arret_deux_ko',
      "Annonce d'arrêt (2 KO) — fratrie" => 'annonce_arret_deux_ko_fratrie',
      'Après 1er KO · Appel 0' => 'apres_premier_ko_appel0',
      'Après 1er KO · Appel 1' => 'apres_premier_ko_appel1',
      'Après 1er KO · Appel 2' => 'apres_premier_ko_appel2',
      'Arrêt · Famille pose problème / Inscrite sans accord / Ne veut pas du programme / Pratiques très avancées' => 'arret_accompagnement',
      'Arrêt · Pas assez francophone' => 'arret_barriere_langue',
      'Arrêt · Professionnel·le de santé qui teste' => 'arret_professionnel_sante',
      "Bienvenue (hors période d'été)" => 'bienvenue',
      "Bienvenue (période d'été)" => 'bienvenue_ete',
      'Confirmation de RDV' => 'confirmation_rdv',
      "Demande de vérification d'adresse (PND)" => 'verification_adresse_pnd',
      'Démarrage tardif' => 'demarrage_tardif',
      "Fin d'accompagnement, étude eval" => 'eval_fin_accompagnement',
      'Fin du programme' => 'fin_programme',
      "Fin du programme (l'enfant a 3 ans)" => 'fin_programme_trois_ans',
      'Garder le lien sur Instagram' => 'instagram_fin_programme',
      'Inscription confirmée (eval25)' => 'inscription_confirmee_eval25',
      'Invitation à choisir le prochain thème' => 'invitation_choix_theme',
      'Invitation à remplir le questionnaire' => 'invitation_questionnaire',
      'Invitation à suivre Instagram' => 'invitation_instagram',
      'Invitation à suivre Instagram (CAF)' => 'invitation_instagram_caf',
      'Message de non-accompagnement' => 'non_accompagnement',
      'Messages aux familles bilingues (J0)' => 'bilingues_j0',
      'Messages aux familles bilingues (J+7)' => 'bilingues_j7',
      'Messages aux familles bilingues (J+14)' => 'bilingues_j14',
      'Numéro qui ne reçoit pas de SMS' => 'numero_sans_sms',
      "Rappel d'inscription CAF (v1)" => 'rappel_inscription_caf_v1',
      "Rappel d'inscription CAF (v2)" => 'rappel_inscription_caf_v2',
      'Rappel de petite mission — appel 0' => 'rappel_mission_appel0',
      'Rappel de petite mission — appel 3' => 'rappel_mission_appel3',
      'Rappel de RDV — jour J (~2h avant)' => 'rappel_rdv_jour_j',
      'Rappel de RDV — la veille (J-1)' => 'rappel_rdv_veille',
      'Relance de dernière chance' => 'relance_derniere_chance',
      'Relance du choix de thème' => 'relance_choix_theme',
      'Repêchage après annulation de RDV' => 'repechage_annulation_rdv',
      "Suggestion d'un lieu d'accueil enfants-parents" => 'suggestion_laep',
      "Vérification de l'adresse" => 'verification_adresse',
      "Vérification de l'adresse pour le livre offert par un partenaire" => 'verification_adresse_livre_partenaire'
    }

    end_of_support_page = Medium.find_by(
      url: 'https://magical-bull-428.notion.site/C-est-la-fin-des-SMS-et-des-livres-1001mots-2826d144b6b04e658f4ea090529fb708?pvs=4'
    )
    links = {
      'Fin du programme' => end_of_support_page,
      "Fin du programme (l'enfant a 3 ans)" => end_of_support_page,
      'Messages aux familles bilingues (J+7)' => Medium.find_by(name: 'URLrecFSkjakLY8MWEvG')
    }

    created = []
    keyed = []
    skipped = []
    texts.each do |name, body|
      key = keys.fetch(name)
      existing = Media::TextMessagesBundle.find_by(key: key) || Media::TextMessagesBundle.kept.find_by(name: name)

      if existing.nil?
        puts "Lien introuvable pour « #{name} »" if links.key?(name) && links[name].nil?
        bundle = Media::TextMessagesBundle.create!(name: name, key: key, body1: body.strip, link1: links[name], tag_list: ['message automatique'])
        created << name
        puts "Créé : #{name} (##{bundle.id})"
      elsif existing.key.blank?
        existing.update_column(:key, key)
        keyed << name
        puts "Clé posée : #{name} (##{existing.id})"
      else
        skipped << name
      end
    end

    skipped.each { |name| puts "Déjà présent, ignoré : #{name}" }
    puts "#{created.size} trio(s) créé(s), #{keyed.size} clé(s) posée(s), #{skipped.size} ignoré(s) sur #{texts.size}."
  end
end
