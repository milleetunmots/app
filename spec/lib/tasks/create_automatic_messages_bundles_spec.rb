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

    expect { task.invoke }.to output(/39 trio\(s\) créé\(s\)/).to_stdout

    bundles = Media::TextMessagesBundle.tagged_with('message automatique')
    expect(bundles.count).to eq(39)
    expect(bundles.pluck(:key)).to all(be_present)
    expect(bundles.pluck(:key).uniq.size).to eq(39)
    expect(Media::TextMessagesBundle.find_by(name: 'Message de continuation')).to be_nil
    expect(Media::TextMessagesBundle.find_by(key: 'demarrage_tardif').body1).to eq(Child::AddToGroupService::LATE_SUPPORT_WARNING_MESSAGE)
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
