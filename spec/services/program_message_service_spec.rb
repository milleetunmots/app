require 'rails_helper'

RSpec.describe ProgramMessageService do

  let_it_be(:parent_1, reload: true) { FactoryBot.create(:parent, first_name: 'Sami') }
  let_it_be(:parent_2, reload: true) { FactoryBot.create(:parent, phone_number: '+33663333333', first_name: 'Fabien') }
  let_it_be(:parent_3, reload: true) { FactoryBot.create(:parent, first_name: 'Aristide') }

  let_it_be(:tag_1, reload: true) { FactoryBot.create(:tag, name: 'giga') }
  let_it_be(:tag_2, reload: true) { FactoryBot.create(:tag, name: 'bien') }

  let_it_be(:tagging_2, reload: true) { FactoryBot.create(:tagging, tag_id: tag_2.id, taggable_id: parent_3.id) }

  let_it_be(:group, reload: true) { FactoryBot.create(:group, name: 'group 1') }

  let_it_be(:medium, reload: true) { FactoryBot.create(:medium, url: 'http://google.com') }
  let_it_be(:redirection_target, reload: true) { FactoryBot.create(:redirection_target, medium_id: medium.id) }

  let_it_be(:child_1, reload: true) do
    FactoryBot.create(
      :child,
      parent1_id: parent_2.id,
      should_contact_parent1: true,
      group_id: group.id,
      group_status: 'active',
      first_name: 'Kevin'
    )
  end

  let_it_be(:child_2, reload: true) do
    FactoryBot.create(
      :child,
      parent1_id: parent_3.id,
      should_contact_parent1: false,
      group_id: group.id,
      group_status: 'active',
      first_name: 'Joe'
    )
  end

  let(:message) { Faker::Lorem.word }

  before do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').
      to_return(status: 200, body: '{}')
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').
      to_return(status: 200, body: { success: true, campaign_id: '123' }.to_json)
  end

  context 'when a tag is given' do
    it 'calls SpotHit::SendRcsService with only parent tagged by it' do
      child_2.update(should_contact_parent1: true)
      expect(SpotHit::SendRcsService).to(
        receive(:new).
        with(
          recipients: [parent_3.phone_number],
          planned_timestamp: Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          fallback_message: message,
          basic: true,
          workshop_id: nil,
          event_params: {},
          replay_params: an_instance_of(Hash),
          blocked_send_attempt_id: nil
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["tag.#{tag_2.id}"],
        message
      ).call
    end
  end

  context 'when parents are given' do
    it 'calls SpotHit::SendRcsService when the message fits in 160 bytes' do
      expect(SpotHit::SendRcsService).to(
        receive(:new).
        with(
          recipients: [parent_3.phone_number],
          planned_timestamp: Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          fallback_message: message,
          basic: true,
          workshop_id: nil,
          event_params: {},
          replay_params: an_instance_of(Hash),
          blocked_send_attempt_id: nil
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_3.id}"],
        message
      ).call
    end

    it 'calls SpotHit::SendSmsService when the message exceeds 160 bytes' do
      long_message = 'a' * 161

      expect(SpotHit::SendSmsService).to(
        receive(:new).
        with(
          parent_3.phone_number,
          Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          long_message,
          workshop_id: nil,
          event_params: {},
          replay_params: an_instance_of(Hash),
          blocked_send_attempt_id: nil
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_3.id}"],
        long_message
      ).call
    end
  end

  context 'when group is given' do
    it 'calls SpotHit::SendRcsService with parents that should be contacted from group only' do
      expect(SpotHit::SendRcsService).to(
        receive(:new).
        with(
          recipients: [parent_2.phone_number],
          planned_timestamp: Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          fallback_message: message,
          basic: true,
          workshop_id: nil,
          event_params: {},
          replay_params: an_instance_of(Hash),
          blocked_send_attempt_id: nil
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["group.#{group.id}"],
        message
      ).call
    end
  end

  context 'when parent and variable are given' do
    it 'calls SpotHit::SendRcsService with parents given only' do
      expect(SpotHit::SendRcsService).to(
        receive(:new).
        with(
          recipients: [parent_2.phone_number],
          planned_timestamp: Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          fallback_message: 'N\'oubliez pas que votre enfant doit faire du sport.',
          basic: true,
          workshop_id: nil,
          event_params: {},
          replay_params: an_instance_of(Hash),
          blocked_send_attempt_id: nil
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_2.id}"],
        'N\'oubliez pas que votre enfant doit faire du sport.',
      ).call
    end
  end

  context 'when parent and url are given' do
    before do
      allow_any_instance_of(RedirectionUrlDecorator).to(
        receive(:visit_url).and_return(
          'http://localhost:3000/r/95/c6'
        )
      )
    end

    it 'calls SpotHit::SendRcsService with parents given only and url place in the message' do
      expect(SpotHit::SendRcsService).to(
        receive(:new).
        with(
          recipients: { parent_2.phone_number => {
            'URL' => 'http://localhost:3000/r/95/c6'
            }
          },
          planned_timestamp: Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          fallback_message: 'N\'oubliez pas que {URL} doit faire du sport.',
          basic: true,
          workshop_id: nil,
          event_params: {},
          replay_params: an_instance_of(Hash),
          blocked_send_attempt_id: nil
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_2.id}"],
        'N\'oubliez pas que {URL} doit faire du sport.',
        nil,
        redirection_target.id
      ).call
    end

    it 'calls SpotHit::SendRcsService with parents given only and url not place in the message' do
      expect(SpotHit::SendRcsService).to(
        receive(:new).
        with(
          recipients: { parent_2.phone_number =>
              {'URL' => 'http://localhost:3000/r/95/c6'}
          },
          planned_timestamp: Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          fallback_message: 'N\'oubliez l\'importance du sport. {URL}',
          basic: true,
          workshop_id: nil,
          event_params: {},
          replay_params: an_instance_of(Hash),
          blocked_send_attempt_id: nil
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_2.id}"],
        'N\'oubliez l\'importance du sport.',
        nil,
        redirection_target.id
      ).call
    end
  end


  context 'when no recipients found' do
    it 'returns errors' do
      service = ProgramMessageService.new('2021-07-12', '14:30:00', [], 'coucou', nil).call
      expect(service.errors).to eq(['La liste des destinataires est vide. Ajoutez au moins un destinataire.'])
    end
  end

  context 'when neither the message nor the redirection URL is given' do
    it 'returns errors' do
      service = ProgramMessageService.new('2021-07-12', '14:30:00', ["parent.#{parent_1.id}"], '', nil).call
      expect(service.errors).to eq(['Un message est requis. Veuillez le compléter.'])
    end
  end

  context 'when the redirection URL is provided and the message is skipped' do
    it 'the message can be skipped' do
      service = ProgramMessageService.new('2021-07-12', '14:30:00', ["parent.#{parent_1.id}"], '', nil, redirection_target.id).call
      expect(service.errors).to_not include 'Un message est requis. Veuillez le compléter.'
    end
  end

  context 'when no parent numbers found' do
    before do
      child_1.update!(should_contact_parent1: false)
    end

    it 'returns errors' do
      service = ProgramMessageService.new('2021-07-12', '14:30:00', ["group.#{group.id}"], 'coucou', nil).call
      expect(service.errors).to eq(['Aucun parent à contacter.'])
    end
  end

  context 'when the message contains a non-whitelisted URL' do
    let(:blocked_message) { 'Cliquez ici : https://non-whitelisted.example.com/page' }

    it 'still calls the SpotHit API but tracks a BlockedSendAttempt (monitoring mode, default)' do
      expect {
        ProgramMessageService.new(
          Time.zone.today,
          Time.zone.now.strftime('%H:%M'),
          ["parent.#{parent_3.id}"],
          blocked_message
        ).call
      }.to change(BlockedSendAttempt, :count).by(1)

      expect(BlockedSendAttempt.last.status).to eq('not_blocked')
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end

    context 'with URL_FILTER_BLOCKING_ENABLED' do
      around do |example|
        previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
        ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
        example.run
        ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
      end

      it 'does not call the SpotHit API and creates a BlockedSendAttempt instead' do
        expect {
          ProgramMessageService.new(
            Time.zone.today,
            Time.zone.now.strftime('%H:%M'),
            ["parent.#{parent_3.id}"],
            blocked_message
          ).call
        }.to change(BlockedSendAttempt, :count).by(1)

        expect(BlockedSendAttempt.last.status).to eq('pending')
        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
      end
    end
  end

  context 'compteur de vidéos suggérées (suggested_videos_counter)' do
    let(:suggested_medium) { FactoryBot.create(:medium, name: 'Appel 3 - vidéos suggérées', url: 'http://google.com') }
    let(:suggested_target) { FactoryBot.create(:redirection_target, medium_id: suggested_medium.id) }
    let(:child_support) { parent_2.current_child.child_support }

    around do |example|
      previous_flag = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
      previous_host = ENV.fetch('DEFAULT_HOSTNAME', nil)
      ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
      ENV['DEFAULT_HOSTNAME'] = 'localhost'
      example.run
      ENV['URL_FILTER_BLOCKING_ENABLED'] = previous_flag
      previous_host.nil? ? ENV.delete('DEFAULT_HOSTNAME') : ENV['DEFAULT_HOSTNAME'] = previous_host
    end

    before do
      allow_any_instance_of(RedirectionUrlDecorator).to(
        receive(:visit_url).and_return('http://localhost:3000/r/95/c6')
      )
    end

    it "n'est pas incrémenté quand l'envoi est bloqué (sinon double comptage à la relance)" do
      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_2.id}"],
        'Cliquez ici : https://non-whitelisted.example.com/page',
        nil,
        suggested_target.id
      ).call

      expect(child_support.reload.suggested_videos_counter).to eq([])
    end

    it "est incrémenté une seule fois quand l'envoi passe" do
      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_2.id}"],
        'Une nouvelle vidéo pour vous.',
        nil,
        suggested_target.id
      ).call

      expect(child_support.reload.suggested_videos_counter.size).to eq(1)
    end
  end

  context 'when replaying a blocked attempt' do
    it 'forwards blocked_send_attempt_id to the provider service' do
      blocked_send_attempt = FactoryBot.create(:blocked_send_attempt)

      expect(SpotHit::SendRcsService).to(
        receive(:new).
        with(hash_including(blocked_send_attempt_id: blocked_send_attempt.id)).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_3.id}"],
        message,
        blocked_send_attempt: blocked_send_attempt
      ).call
    end
  end

  # ---------------------------------------------------------------------------
  # Plafonnement anti-fraude du nombre de destinataires
  # ---------------------------------------------------------------------------

  describe 'plafonnement du nombre de destinataires' do
    let(:acting_admin_user) { FactoryBot.create(:admin_user, user_role: 'contributor') }
    # Message dépassant 160 octets : force la route SMS plutôt que le RCS basic.
    let(:long_message) { 'a' * 400 }

    def program(recipients, body = message, **options)
      described_class.new(
        options.fetch(:planned_date, Time.zone.today),
        Time.zone.now.strftime('%H:%M'),
        recipients,
        body,
        nil,
        nil,
        false,
        nil,
        nil,
        options.fetch(:group_status, ['active']),
        options.fetch(:provider, 'spothit'),
        options[:aircall_number_id],
        acting_admin_user: options.fetch(:acting_admin_user, acting_admin_user)
      ).call
    end

    # Consomme du quota au nom de l'utilisatrice sans passer par un envoi réel.
    def consume(count, ago = 10.minutes.ago, user: acting_admin_user)
      FactoryBot.create(:sms_send_record, admin_user: user, recipients_count: count, created_at: ago)
    end

    context 'comptage' do
      it 'enregistre un envoi avec le nombre de destinataires transmis' do
        child_2.update(should_contact_parent1: true)

        program(["parent.#{parent_2.id}", "parent.#{parent_3.id}"])

        expect(SmsSendRecord.last.recipients_count).to eq(2)
      end

      it "compte aussi les destinataires d'un message long, parti en SMS" do
        child_2.update(should_contact_parent1: true)

        program(["parent.#{parent_2.id}", "parent.#{parent_3.id}"], long_message)

        expect(SmsSendRecord.last.recipients_count).to eq(2)
      end

      it 'compte pour deux un enfant dont les deux parents sont à contacter' do
        child_1.update(parent2_id: parent_1.id, should_contact_parent2: true)

        program(["child.#{child_1.id}"])

        expect(SmsSendRecord.last.recipients_count).to eq(2)
      end

      it "ne compte qu'une fois un destinataire sélectionné deux fois" do
        program(["parent.#{parent_2.id}", "group.#{group.id}"])

        expect(SmsSendRecord.last.recipients_count).to eq(1)
      end

      it "ne compte pas les destinataires écartés parce qu'ils ne sont pas valides" do
        child_2.update(should_contact_parent1: true)
        # postal_code est NOT NULL en base : on le rend invalide sans le vider
        # (numericality + length: 5 échouent), ce qui suffit à écarter le parent.
        parent_3.update_column(:postal_code, 'abc')

        program(["parent.#{parent_2.id}", "parent.#{parent_3.id}"])

        expect(SmsSendRecord.last.recipients_count).to eq(1)
      end

      it "horodate l'enregistrement à l'instant de la programmation, pas à la date d'envoi" do
        program(["parent.#{parent_2.id}"], message, planned_date: 3.days.from_now.to_date)

        expect(SmsSendRecord.last.created_at).to be_within(5.seconds).of(Time.zone.now)
      end
    end

    context 'quand le plafond est atteint' do
      before { consume(50) }

      it "retourne le message d'erreur de dépassement" do
        service = program(["parent.#{parent_2.id}"])

        expect(service.errors).to eq(["Vous avez atteint la limite d'envoi de messages. Aucun message n'a pu être envoyé. Contactez un admin."])
      end

      it 'signale le dépassement via quota_exceeded?' do
        expect(program(["parent.#{parent_2.id}"])).to be_quota_exceeded
      end

      it "n'appelle pas l'API Spot-Hit" do
        program(["parent.#{parent_2.id}"])

        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
      end

      it 'ne crée aucun événement de SMS envoyé' do
        expect { program(["parent.#{parent_2.id}"]) }.not_to change(Events::TextMessage, :count)
      end

      it "ne crée aucun enregistrement d'envoi" do
        expect { program(["parent.#{parent_2.id}"]) }.not_to change(SmsSendRecord, :count)
      end

      it 'bloque aussi les messages courts, qui partent en RCS basic' do
        expect(program(["parent.#{parent_2.id}"], 'court')).to be_quota_exceeded
      end
    end

    context 'dépassement partiel' do
      it "bloque la totalité de l'envoi" do
        child_2.update(should_contact_parent1: true)
        consume(49)

        service = program(["parent.#{parent_2.id}", "parent.#{parent_3.id}"])

        expect(service).to be_quota_exceeded
        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
      end
    end

    context 'programmation dans le futur' do
      it 'consomme le quota immédiatement et bloque' do
        consume(49)
        child_2.update(should_contact_parent1: true)

        service = program(["parent.#{parent_2.id}", "parent.#{parent_3.id}"], message, planned_date: 3.days.from_now.to_date)

        expect(service).to be_quota_exceeded
      end
    end

    context "quand l'appel Spot-Hit échoue" do
      before do
        stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').
          to_return(status: 200, body: { erreurs: ['nope'] }.to_json)
      end

      it "n'incrémente pas le compteur" do
        expect { program(["parent.#{parent_2.id}"]) }.not_to change(SmsSendRecord, :count)
      end

      it "retourne l'erreur de Spot-Hit et non une erreur de plafond" do
        service = program(["parent.#{parent_2.id}"])

        expect(service).not_to be_quota_exceeded
        expect(service.errors.first).to match(/Erreur lors de la programmation de la campagne/)
      end
    end

    context "quand l'envoi n'atteint pas le contrôle de plafond" do
      it 'ne consomme pas de quota sans destinataire éligible' do
        service = nil

        expect { service = program(["parent.#{parent_1.id}"]) }.not_to change(SmsSendRecord, :count)
        expect(service.errors).to eq(['Aucun parent à contacter.'])
      end

      it 'ne consomme pas de quota si le message est vide' do
        service = nil

        expect { service = program(["parent.#{parent_2.id}"], '') }.not_to change(SmsSendRecord, :count)
        expect(service.errors).to include('Un message est requis. Veuillez le compléter.')
      end
    end

    context 'périmètre exclu' do
      it "ne limite ni ne compte les envois sans utilisatrice à l'origine" do
        consume(50)

        service = nil
        expect { service = program(["parent.#{parent_2.id}"], message, acting_admin_user: nil) }
          .not_to change(SmsSendRecord, :count)
        expect(service).not_to be_quota_exceeded
      end

      it "ne limite ni ne compte les envois d'un super_admin" do
        super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
        consume(500, 10.minutes.ago, user: super_admin)

        service = nil
        expect { service = program(["parent.#{parent_2.id}"], message, acting_admin_user: super_admin) }
          .not_to change(SmsSendRecord, :count)
        expect(service).not_to be_quota_exceeded
      end

      it 'ne limite ni ne compte les envois Aircall' do
        consume(50)

        service = nil
        expect do
          service = program(["parent.#{parent_2.id}"], message, provider: 'aircall', aircall_number_id: 42)
        end.not_to change(SmsSendRecord, :count)
        expect(service).not_to be_quota_exceeded
      end
    end

    context "compteur partagé entre points d'entrée" do
      it "additionne les envois de tous les points d'entrée" do
        # 30 invitations d'atelier puis 15 destinataires depuis le formulaire.
        consume(30)
        consume(15)
        child_2.update(should_contact_parent1: true)

        expect(program(["parent.#{parent_2.id}", "parent.#{parent_3.id}"])).not_to be_quota_exceeded

        consume(4)
        expect(program(["parent.#{parent_2.id}", "parent.#{parent_3.id}"])).to be_quota_exceeded
      end
    end
  end
end
