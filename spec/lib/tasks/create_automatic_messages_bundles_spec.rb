require 'rails_helper'
require 'rake'

RSpec.describe 'text_messages_bundles:create_automatic_messages' do
  before(:all) do
    Rake.application.rake_require('tasks/create_automatic_messages_bundles', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['text_messages_bundles:create_automatic_messages'] }

  before { task.reenable }

  def end_of_support_page
    FactoryBot.create(
      :media_video,
      url: 'https://magical-bull-428.notion.site/C-est-la-fin-des-SMS-et-des-livres-1001mots-2826d144b6b04e658f4ea090529fb708?pvs=4'
    )
  end

  def bilingual_video
    FactoryBot.create(:media_video, name: 'URLrecFSkjakLY8MWEvG')
  end

  it 'crée un trio étiqueté « message automatique » par message, chacun avec sa clé, sans le message de continuation' do
    end_of_support_page
    bilingual_video

    expect { task.invoke }.to output(/40 trio\(s\) créé\(s\)/).to_stdout

    bundles = Media::TextMessagesBundle.tagged_with('message automatique')
    expect(bundles.count).to eq(40)
    expect(bundles.pluck(:key)).to all(be_present)
    expect(bundles.pluck(:key).uniq.size).to eq(40)
    expect(Media::TextMessagesBundle.find_by(name: 'Message de continuation')).to be_nil
  end

  it 'pose le lien des trios de fin du programme et du message bilingue de J+7' do
    page = end_of_support_page
    video = bilingual_video

    task.invoke

    expect(Media::TextMessagesBundle.find_by(key: 'fin_programme').link1_id).to eq(page.id)
    expect(Media::TextMessagesBundle.find_by(key: 'fin_programme_trois_ans').link1_id).to eq(page.id)
    expect(Media::TextMessagesBundle.find_by(key: 'bilingues_j7').link1_id).to eq(video.id)
    expect(Media::TextMessagesBundle.find_by(key: 'bilingues_j0').link1_id).to be_nil
  end

  it "remplace les valeurs statiques et reprend les variables de l'envoi" do
    previous_link = ENV.fetch('INSTAGRAM_LINK', nil)
    ENV['INSTAGRAM_LINK'] = 'https://instagram.com/1001mots'

    task.invoke

    expect(Media::TextMessagesBundle.find_by(key: 'invitation_instagram').body1)
      .to eq('1001mots : En attendant que votre accompagnement 1001mots commence, retrouvez sur Instagram nos idées d’activités ' \
             'et nos conseils pour occuper {PRENOM_ENFANT}, abonnez-vous ! https://instagram.com/1001mots')
    expect(Media::TextMessagesBundle.find_by(key: 'annonce_arret_deux_ko_fratrie').body1).to include('beaux moments avec vos enfants')
    expect(Media::TextMessagesBundle.find_by(key: 'confirmation_rdv').body1)
      .to include('{RDV_CALENDLY_SCHEDULED_AT_HOUR}', '{RDV_CALENDLY_CANCEL_URL}')
    expect(Media::TextMessagesBundle.find_by(key: 'rappel_mission_appel3').body1).to end_with('Bonne journée :)')
    expect(Media::TextMessagesBundle.find_by(key: 'fin_programme').body1).to start_with("C'est maintenant la fin des SMS et des livres 1001mots")
  ensure
    previous_link.nil? ? ENV.delete('INSTAGRAM_LINK') : ENV['INSTAGRAM_LINK'] = previous_link
  end

  it "crée les trios d'arrêt et de désengagement avec le texte actuel de leur message, sans guillemet en trop" do
    disengagement = "Bonjour,\n{PRENOM_ACCOMPAGNANTE} a essayé de vous appeler plusieurs fois mais n'a pas réussi à discuter avec vous. " \
                    "Avec 1001mots, quand on n'arrive pas à échanger, l'accompagnement se termine pour que d'autres familles en profitent. " \
                    "Les livres et SMS vont donc s'arrêter bientôt.\nMerci d'avoir participé à ce programme. On vous souhaite de beaux " \
                    "moments avec {PRENOM_ENFANT} !\nEt si vous avez encore 1 minute, dites-nous ici ce que vous avez pensé de 1001mots : " \
                    "https://form.typeform.com/to/fysdS3Sd#st=xxxxx\nL'équipe 1001mots"
    later_calls_warning = "Bonjour,\n{PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois, mais vous n'étiez " \
                          "pas disponible. C'est dommage, parce que c'est super important pour adapter nos astuces à votre famille. Elle vous " \
                          "rappellera dans %<delay>s.\nSi elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera " \
                          "automatiquement et vous n'allez plus recevoir de livres ni de SMS :(\nA bientôt !\n%<signature>s"
    expected_texts = {
      'annonce_arret_deux_ko' => disengagement,
      'annonce_arret_deux_ko_fratrie' => disengagement.sub('{PRENOM_ENFANT}', 'vos enfants'),
      'apres_premier_ko_appel0' =>
        "Bonjour,\n{PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois. C’est dommage que vous " \
        "n'ayez pas pu discuter avec elle, parce que c’est super important pour adapter nos astuces à votre famille. Dans 2 semaines, " \
        'vous allez recevoir le 1er livre pour {PRENOM_ENFANT}. {PRENOM_ACCOMPAGNANTE} vous appellera ensuite pour en parler avec ' \
        "vous.\nSi elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera automatiquement et vous n'allez plus " \
        "recevoir de livres ni de SMS :( Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}\nA bientôt !\nL’équipe 1001mots",
      'apres_premier_ko_appel1' => format(later_calls_warning, delay: 'quelques semaines', signature: "L'équipe 1001mots"),
      'apres_premier_ko_appel2' => format(later_calls_warning, delay: '3 mois', signature: 'L’équipe 1001mots'),
      'arret_accompagnement' =>
        "Bonjour, Votre accompagnement 1001mots s'arrête. Pour des raisons techniques, vous allez recevoir encore quelques SMS, " \
        "répondez STOP si vous voulez les arrêter.\nSi vous avez quelques minutes pour nous faire un retour sur 1001mots, ce serait " \
        'très utile : https://form.typeform.com/to/oy3wjinA#st=xxxxx',
      'arret_barriere_langue' =>
        '1001mots : Bonjour, votre accompagnement s’arrête. Nous sommes désolés de ne pas pouvoir vous accompagner dans votre ' \
        "langue...\nVoici une playlist Youtube de vidéos dans plein de langues, il y aura peut-être la vôtre : " \
        'https://www.youtube.com/@papotoparentalitepourtous7726/playlists',
      'arret_professionnel_sante' =>
        "1001mots: Merci de l'intérêt que vous portez à l'association ! Le programme est réservé aux familles adressées par nos " \
        "partenaires, nous devons donc mettre fin à l’accompagnement.\nSi vous êtes un.e professionnel de PMI, écrivez-nous à " \
        'l’adresse pmi@1001mots.org.'
    }

    task.invoke

    expect(Media::TextMessagesBundle.where(key: expected_texts.keys).pluck(:key, :body1).to_h).to eq(expected_texts)
  end

  it "crée les trios de la demande de vérification d'adresse (PND) et du numéro sans SMS avec le texte actuel de leur message" do
    expected_texts = {
      'verification_adresse_pnd' =>
        "1001mots : Vous n'avez pas reçu votre dernier livre ? Vérifiez votre adresse sur ce lien : " \
        "https://form.typeform.com/to/#{ENV.fetch('UPDATING_ADDRESS_TYPEFORM_ID', nil)}#st=xxxxx",
      'numero_sans_sms' =>
        "1001mots: Ce numéro ne peut pas recevoir de SMS. Pour nous contacter, merci d'envoyer vos messages directement à " \
        '{PRENOM_ACCOMPAGNANTE} au {NUMERO_AIRCALL_ACCOMPAGNANTE}. Merci!'
    }

    task.invoke

    expect(Media::TextMessagesBundle.where(key: expected_texts.keys).pluck(:key, :body1).to_h).to eq(expected_texts)
  end

  it 'crée les trios des messages à valeurs de famille avec le texte actuel de leur message, et le trio du rappel de la 2e semaine' do
    call_goals_reminder = "Bonjour\nVoici un rappel de votre petite mission 1001mots :\n{PETITE_MISSION}\nEt pour me raconter comment ça c'est passé, " \
                          "c'est ici :\n{LIEN_SUIVI_PETITE_MISSION}\n%<closing>s"
    expected_texts = {
      'confirmation_rdv' =>
        "1001mots : Confirmation de RDV\nBonjour,\nVous avez RDV le {SCHEDULED_AT_DATE} avec {PRENOM_ACCOMPAGNANTE}, votre accompagnante " \
        '1001mots. Elle vous appellera vers {RDV_CALENDLY_SCHEDULED_AT_HOUR} sur votre numéro.' \
        "\nL'appel durera environ 20 minutes. Pensez à enregistrer son numéro pour ne pas manquer l'appel : {NUMERO_AIRCALL_ACCOMPAGNANTE}." \
        "\nSi vous n’êtes plus disponible, annulez le rdv ici : {RDV_CALENDLY_CANCEL_URL}\nA bientôt !",
      'repechage_annulation_rdv' =>
        "1001mots : Bonjour, vous venez d’annuler votre RDV avec {PRENOM_ACCOMPAGNANTE}.\nVous pouvez choisir un autre créneau pour lui " \
        "parler ici : {CALENDLY_LINK}\nA bientôt !",
      'demarrage_tardif' =>
        '1001mots : En raison d’un grand nombre de demandes, vous recevrez nos livres et conseils dans environ 2 mois. Pas d’inquiétude, ' \
        "c'est normal si vous avez moins de nouvelles de nous d'ici là. A bientôt!",
      'rappel_mission_appel0' =>
        "1001mots: Je n'ai pas réussi à vous joindre cette fois-ci, tant pis! Voici un rappel de votre petite mission de la dernière " \
        "fois:\n{PETITE_MISSION}\nVous pouvez me dire si vous avez essayé en cliquant sur ce lien:\n{LIEN_SUIVI_PETITE_MISSION}\nÀ bientôt!",
      'rappel_mission_appel3' => format(call_goals_reminder, closing: 'Bonne journée :)'),
      'rappel_mission_deux_semaines' => format(call_goals_reminder, closing: 'À bientôt :)'),
      'verification_adresse' =>
        "1001mots : Bonjour, nous allons bientôt envoyer un livre pour {PRENOM_ENFANT}. Nous allons l'envoyer à l'adresse suivante : " \
        "\n{PARENT_ADDRESS}\nSi l'adresse postale ou le nom sur la boîte aux lettres ne sont pas bons, merci de les modifier ici : " \
        "https://form.typeform.com/to/#{ENV.fetch('UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID', nil)}#st=xxxxx"
    }

    task.invoke

    expect(Media::TextMessagesBundle.where(key: expected_texts.keys).pluck(:key, :body1).to_h).to eq(expected_texts)
    expect(Media::TextMessagesBundle.find_by(key: 'rappel_mission_deux_semaines').name).to eq('Rappel de petite mission — 2 semaines')
  end

  it 'crée les trios des rappels de RDV avec le texte actuel de leur rappel' do
    reminder = "1001mots : Rappel de RDV\nBonjour,\nVous avez RDV %<day>s avec {PRENOM_ACCOMPAGNANTE}, votre accompagnante. Elle vous " \
               'appellera vers {RDV_CALENDLY_SCHEDULED_AT_HOUR} sur votre numéro.%<delay>s Pensez à enregistrer son numéro pour ne pas ' \
               "manquer l’appel : {NUMERO_AIRCALL_ACCOMPAGNANTE}.\nSi vous n'êtes plus disponible, annulez le rdv ici : " \
               "{RDV_CALENDLY_CANCEL_URL}\nA bientôt !"
    expected_texts = {
      'rappel_rdv_veille' => format(reminder, day: 'demain', delay: ''),
      'rappel_rdv_jour_j' => format(reminder, day: 'aujourd’hui', delay: ' Elle aura peut-être quelques minutes d’avance ou de retard.')
    }

    task.invoke

    expect(Media::TextMessagesBundle.where(key: expected_texts.keys).pluck(:key, :body1).to_h).to eq(expected_texts)
  end

  it 'pose le lien des conseils sur le trio de non-accompagnement' do
    advice = FactoryBot.create(:media_form, name: 'Lien - non accompagnement', url: 'https://example.org/conseils')

    task.invoke

    expect(Media::TextMessagesBundle.find_by(key: 'non_accompagnement').link1_id).to eq(advice.id)
  end

  it 'crée le trio de non-accompagnement sans lien et le signale quand le média des conseils est introuvable' do
    expect { task.invoke }.to output(/Lien introuvable pour « Message de non-accompagnement »/).to_stdout

    expect(Media::TextMessagesBundle.find_by(key: 'non_accompagnement').link1_id).to be_nil
  end

  it "pose la clé sur un trio du même nom qui n'en a pas, sans changer son texte" do
    existing = FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme', body1: "Texte modifié par l'équipe", body2: nil, body3: nil)

    expect { task.invoke }.to output(/Clé posée : Fin du programme/).to_stdout

    expect(existing.reload).to have_attributes(key: 'fin_programme', body1: "Texte modifié par l'équipe")
    expect(Media::TextMessagesBundle.where(name: 'Fin du programme').count).to eq(1)
  end

  it 'ne crée pas de trio pour une clé déjà portée par un trio renommé' do
    renamed = FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme — v2', body2: nil, body3: nil)
    renamed.update_column(:key, 'fin_programme')

    expect { task.invoke }.to output(/Déjà présent, ignoré : Fin du programme/).to_stdout

    expect(Media::TextMessagesBundle.where(key: 'fin_programme')).to eq([renamed])
    expect(Media::TextMessagesBundle.find_by(name: 'Fin du programme')).to be_nil
  end

  it 'crée le trio sans lien et le signale quand le média du lien est introuvable' do
    bilingual_video

    expect { task.invoke }.to output(/Lien introuvable pour « Fin du programme »/).to_stdout

    expect(Media::TextMessagesBundle.find_by(key: 'fin_programme').link1_id).to be_nil
  end
end
