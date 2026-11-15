require 'rails_helper'
require 'rake'

RSpec.describe 'text_messages_bundles:create_automatic_messages' do
  before(:all) do
    Rake.application.rake_require('tasks/create_automatic_messages_bundles', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['text_messages_bundles:create_automatic_messages'] }

  before { task.reenable }

  it 'crée un trio étiqueté « message automatique » par message, avec le texte du code' do
    expect { task.invoke }.to output(/40 trio\(s\) créé\(s\), 0 ignoré\(s\) sur 40/).to_stdout

    bundle = Media::TextMessagesBundle.find_by(name: 'Démarrage tardif')
    expect(bundle.body1).to eq(Child::AddToGroupService::LATE_SUPPORT_WARNING_MESSAGE)
    expect(bundle.tag_list).to eq(['message automatique'])
    expect(bundle.body2).to be_nil
  end

  it "remplace les valeurs statiques et reprend les variables de l'envoi" do
    previous_link = ENV.fetch('INSTAGRAM_LINK', nil)
    ENV['INSTAGRAM_LINK'] = 'https://instagram.com/1001mots'

    task.invoke

    expect(Media::TextMessagesBundle.find_by(name: 'Invitation à suivre Instagram').body1)
      .to eq('1001mots : En attendant que votre accompagnement 1001mots commence, retrouvez sur Instagram nos idées d’activités ' \
             'et nos conseils pour occuper {PRENOM_ENFANT}, abonnez-vous ! https://instagram.com/1001mots')
    expect(Media::TextMessagesBundle.find_by(name: "Annonce d'arrêt (2 KO) — fratrie").body1).to include('beaux moments avec vos enfants')
    expect(Media::TextMessagesBundle.find_by(name: 'Confirmation de RDV').body1)
      .to include('{RDV_CALENDLY_SCHEDULED_AT_HOUR}', '{RDV_CALENDLY_CANCEL_URL}')
    expect(Media::TextMessagesBundle.find_by(name: 'Rappel de petite mission — appel 3').body1).to end_with('Bonne journée :)')
  ensure
    previous_link.nil? ? ENV.delete('INSTAGRAM_LINK') : ENV['INSTAGRAM_LINK'] = previous_link
  end

  it 'ne recrée pas un trio dont le nom existe et ne modifie pas son texte' do
    FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme', body1: "Texte modifié par l'équipe", body2: nil, body3: nil)

    expect { task.invoke }.to output(/Déjà présent, ignoré : Fin du programme.*39 trio\(s\) créé\(s\), 1 ignoré\(s\) sur 40/m).to_stdout

    expect(Media::TextMessagesBundle.where(name: 'Fin du programme').pluck(:body1)).to eq(["Texte modifié par l'équipe"])
  end
end
