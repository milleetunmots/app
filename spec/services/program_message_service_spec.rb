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
      group_status: "active",
      first_name: 'Kevin'
    )
  end

  let_it_be(:child_2, reload: true) do
    FactoryBot.create(
      :child,
      parent1_id: parent_3.id,
      should_contact_parent1: false,
      group_id: group.id,
      group_status: "active",
      first_name: 'Joe'
    )
  end

  let(:message) { Faker::Lorem.word }

  before do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').
      to_return(status: 200, body: '{}')
  end

  context 'when a tag is given' do
    it 'calls SpotHit::SendSmsService with only parent tagged by it' do
      expect(SpotHit::SendSmsService).to(
        receive(:new).
        with(
          [parent_3.id],
          Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          message,
          workshop_id: nil,
          event_params: {}
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
    it 'calls SpotHit::SendSmsService with parents given only' do
      expect(SpotHit::SendSmsService).to(
        receive(:new).
        with(
          [parent_3.id],
          Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          message,
          workshop_id: nil,
          event_params: {}
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
  end

  context 'when group is given' do
    it 'calls SpotHit::SendSmsService with parents that should be contacted from group only' do
      expect(SpotHit::SendSmsService).to(
        receive(:new).
        with(
          [parent_2.id],
          Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          message,
          workshop_id: nil,
          event_params: {}
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
    it 'calls SpotHit::SendSmsService with parents given only' do
      expect(SpotHit::SendSmsService).to(
        receive(:new).
        with(
          { parent_2.id.to_s => {'CHILD_SUPPORT_ID' => parent_2.current_child.child_support_id, 'PRENOM_ENFANT' => parent_2.current_child.first_name, 'NUMERO_AIRCALL_ACCOMPAGNANTE' => nil, 'PRENOM_ACCOMPAGNANTE' => nil} },
          Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          'N\'oubliez pas que {PRENOM_ENFANT} doit faire du sport.', workshop_id: nil, event_params: {}
        ).
        and_call_original
      )

      ProgramMessageService.new(
        Time.zone.today,
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{parent_2.id}"],
        'N\'oubliez pas que {PRENOM_ENFANT} doit faire du sport.',
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

    it 'calls SpotHit::SendSmsService with parents given only and url place in the message' do
      expect(SpotHit::SendSmsService).to(
        receive(:new).
        with(
          { parent_2.id.to_s => {
            'CHILD_SUPPORT_ID' => parent_2.current_child.child_support_id,
            'PRENOM_ENFANT' => parent_2.current_child.first_name,
            'URL' => 'http://localhost:3000/r/95/c6',
            'NUMERO_AIRCALL_ACCOMPAGNANTE' => nil,
            'PRENOM_ACCOMPAGNANTE' => nil
            }
          },
          Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          'N\'oubliez pas que {URL} doit faire du sport.',
          workshop_id: nil,
          event_params: {}
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

    it 'calls SpotHit::SendSmsService with parents given only and url not place in the message' do
      expect(SpotHit::SendSmsService).to(
        receive(:new).
        with(
          { parent_2.id.to_s => {
            'CHILD_SUPPORT_ID' => parent_2.current_child.child_support_id,
            'PRENOM_ENFANT' => parent_2.current_child.first_name,
            'URL' => 'http://localhost:3000/r/95/c6',
            'NUMERO_AIRCALL_ACCOMPAGNANTE' => nil,
            'PRENOM_ACCOMPAGNANTE' => nil
            }
          },
          Time.zone.parse("#{Time.zone.today} #{Time.zone.now.strftime('%H:%M')}").to_i,
          'N\'oubliez l\'importance du sport. {URL}',
          workshop_id: nil,
          event_params: {}
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

end
