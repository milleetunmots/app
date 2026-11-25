require 'rails_helper'

RSpec.describe Group::StopSupportService do
  def campaign_texts
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                            .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                            .map { |signature| Rack::Utils.parse_nested_query(signature.body) }
                            .map { |form| form['fallback_message'] || form['message'] }
  end

  def end_of_support_bundle(name:, body:, key: nil)
    bundle = FactoryBot.create(:media_text_messages_bundle, name: name, body1: body, body2: nil, body3: nil)
    bundle.update_column(:key, key) if key
    bundle
  end

  def stop_lea_group
    group = FactoryBot.create(:group)
    child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
    WebMock::RequestRegistry.instance.reset!
    service = described_class.new(group.id).call
    [service, child]
  end

  describe '#call en fin d\'accompagnement' do
    context 'pour trouver le trio du message de fin' do
      it 'prend le seul trio qui porte le nom « Fin du programme »' do
        end_of_support_bundle(name: 'Fin du programme', body: 'Texte du trio unique.', key: 'fin_programme')

        stop_lea_group

        expect(campaign_texts).to include('Texte du trio unique.')
      end

      it 'prend le trio de clé fin_programme quand aucun trio ne porte le nom' do
        end_of_support_bundle(name: 'Fin du programme — v2', body: 'Texte du trio renommé.', key: 'fin_programme')

        stop_lea_group

        expect(campaign_texts).to include('Texte du trio renommé.')
      end

      it 'prend le trio de clé fin_programme quand plusieurs trios portent le nom' do
        end_of_support_bundle(name: 'Fin du programme', body: 'Texte sans clé.')
        end_of_support_bundle(name: 'Fin du programme', body: 'Texte avec clé.', key: 'fin_programme')

        stop_lea_group

        expect(campaign_texts).to include('Texte avec clé.')
        expect(campaign_texts).not_to include('Texte sans clé.')
      end

      it "prend le nouveau trio du nom quand l'ancien, renommé, garde la clé" do
        end_of_support_bundle(name: 'Fin du programme — v2', body: 'Texte de l’ancien trio.', key: 'fin_programme')
        end_of_support_bundle(name: 'Fin du programme', body: 'Texte du nouveau trio.')

        stop_lea_group

        expect(campaign_texts).to include('Texte du nouveau trio.')
        expect(campaign_texts).not_to include('Texte de l’ancien trio.')
      end
    end

    it "envoie le texte modifié par l'équipe, avec le prénom de l'enfant et le lien du trio" do
      bundle = end_of_support_bundle(
        name: 'Fin du programme',
        body: "C'est la fin de l'accompagnement 1001mots pour {PRENOM_ENFANT}. {URL}",
        key: 'fin_programme'
      )
      bundle.update_column(:link1_id, FactoryBot.create(:media_video).id)

      stop_lea_group

      request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                                        .find { |signature| signature.body.to_s.include?('fin+de+l%27accompagnement') }
      form = Rack::Utils.parse_nested_query(request.body)
      expect(form['fallback_message'] || form['message']).to eq("C'est la fin de l'accompagnement 1001mots pour {PRENOM_ENFANT}. {URL}")
      expect(request.body).to include('L%C3%A9a')
      expect(CGI.unescape(request.body)).to include('[URL]')
    end

    context 'quand le trio du message de fin est introuvable' do
      [
        ['aucun trio ne porte le nom ni la clé', -> {}],
        ['le seul trio de la clé est archivé', -> {
          FactoryBot.create(:media_text_messages_bundle, name: 'Ancien', body1: 'Archivé.', body2: nil, body3: nil)
                    .update_columns(key: 'fin_programme', discarded_at: Time.current)
        }],
        ['le seul trio de la clé est en brouillon', -> {
          FactoryBot.create(:media_text_messages_bundle, name: 'Brouillon', body1: 'Brouillon.', body2: nil, body3: nil)
                    .update_columns(key: 'fin_programme', type: 'Media::TextMessagesBundleDraft')
        }],
        ['deux trios portent le nom et aucun la clé', -> {
          2.times { FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme', body1: 'Homonyme.', body2: nil, body3: nil) }
        }]
      ].each do |situation, setup|
        it "n'envoie aucun message de fin et signale le nom et la clé cherchés quand #{situation}" do
          setup.call
          allow(Rollbar).to receive(:error)

          stop_lea_group

          expect(campaign_texts.compact.reject { |text| text.start_with?('1001mots vous manque') }).to be_empty
          expect(Rollbar).to have_received(:error).with(include(a_string_including('Fin du programme', 'fin_programme')))
        end
      end
    end
  end

  describe '#call avec les trios de fin et d\'Instagram' do
    def with_rcs_single_text
      previous = ENV.fetch('RCS_SINGLE_TEXT_ENABLED', nil)
      ENV['RCS_SINGLE_TEXT_ENABLED'] = 'true'
      yield
    ensure
      previous.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = previous
    end

    def campaigns
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                              .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                              .map { |signature| Rack::Utils.parse_nested_query(signature.body).merge('endpoint' => signature.uri.path) }
    end

    def end_page
      FactoryBot.create(:media_video, url: 'https://1001mots.notion.site/fin')
    end

    def text_bundle(name:, key:, body:, link: nil, rcs_media_id: nil)
      bundle = FactoryBot.create(:media_text_messages_bundle, name: name, body1: body, body2: nil, body3: nil)
      bundle.update_columns(key: key, link1_id: link&.id, rcs_media1_id: rcs_media_id, rcs_text_template1: rcs_media_id.present?)
      bundle
    end

    [
      { key: 'fin_programme', name: 'Fin du programme', end_of_support: true, age_in_months: 20 },
      { key: 'fin_programme_trois_ans', name: "Fin du programme (l'enfant a 3 ans)", end_of_support: false, age_in_months: 36 }
    ].each do |example|
      it "programme le message #{example[:key]} en RCS single texte avec le modèle et le lien du trio" do
        page = end_page
        text_bundle(name: example[:name], key: example[:key], body: "Fin pour {PRENOM_ENFANT} : {URL} #{'a' * 260}", link: page, rcs_media_id: 4521)
        group = FactoryBot.create(:group)
        child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
        child.update_column(:birthdate, example[:age_in_months].months.ago.to_date)
        WebMock::RequestRegistry.instance.reset!

        with_rcs_single_text { described_class.new(group.id, end_of_support: example[:end_of_support]).call }

        campaign = campaigns.find { |c| c['fallback_message'].to_s.start_with?('Fin pour') }
        expect(campaign).to include('endpoint' => '/api/envoyer/rcs', 'rcs_type' => 'single', 'media_id' => '4521')
        expect(RedirectionUrl.find_by(parent: child.parent1).redirection_target.medium).to eq(page)
      end
    end

    it 'programme le texte du trio Instagram de fin pour le parent de Léa dans un mois' do
      text_bundle(name: 'Fin du programme', key: 'fin_programme', body: 'Fin du programme.')
      text_bundle(name: 'Garder le lien sur Instagram', key: 'instagram_fin_programme', body: 'Suivez-nous sur Instagram !')
      group = FactoryBot.create(:group)
      child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
      child.update_column(:birthdate, 20.months.ago.to_date)
      WebMock::RequestRegistry.instance.reset!

      described_class.new(group.id).call

      campaign = campaigns.find { |c| (c['fallback_message'] || c['message']) == 'Suivez-nous sur Instagram !' }
      expect(campaign['date']).to start_with(Time.zone.today.advance(months: 1).strftime('%Y-%m-%d'))
    end

    it 'arrête quand même le groupe sans envoyer de message de fin quand son trio est introuvable' do
      allow(Rollbar).to receive(:error)
      text_bundle(name: 'Garder le lien sur Instagram', key: 'instagram_fin_programme', body: 'Suivez-nous sur Instagram !')
      group = FactoryBot.create(:group)
      child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
      WebMock::RequestRegistry.instance.reset!

      described_class.new(group.id).call

      expect(child.reload.group_status).to eq('stopped')
      expect(campaigns.map { |c| c['fallback_message'] || c['message'] }).to eq(['Suivez-nous sur Instagram !'])
      expect(Rollbar).to have_received(:error).with(include(a_string_including('Fin du programme')))
    end
  end
end
