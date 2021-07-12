require 'rails_helper'

RSpec.describe ProgramMessageService do

  let_it_be(:parent_1, reload: true) { FactoryBot.create(:parent, first_name: 'Sami') }
  let_it_be(:parent_2, reload: true) { FactoryBot.create(:parent, phone_number: '+33563333333', first_name: 'Fabien') }
  let_it_be(:parent_3, reload: true) { FactoryBot.create(:parent, first_name: 'Aristide') }
    
  let_it_be(:tag_1, reload: true) { FactoryBot.create(:tag, name: 'giga') }
  let_it_be(:tag_2, reload: true) { FactoryBot.create(:tag, name: 'bien') }

  let_it_be(:tagging_2, reload: true) { FactoryBot.create(:tagging, tag_id: tag_2.id, taggable_id: parent_3.id) }

  let_it_be(:group, reload: true) { FactoryBot.create(:group, name: 'Groupe des minimoys') }
  
  let_it_be(:child_1, reload: true) { FactoryBot.create(
    :child,
    parent1_id: parent_1.id,
    should_contact_parent1: false,
    group_id: group.id,
    first_name: 'Kevin'
  )}

  let_it_be(:child_2, reload: true) { FactoryBot.create(
    :child,
    parent1_id: parent_3.id,
    should_contact_parent1: false,
    first_name: 'Joe'
  )}

  context 'valid' do
    # TODO: issue with the timezone
    # it 'valid data for sending', tz: 'Paris' do
    #   expect(SpotHit::SendSmsService).to(
    #     receive(:new).
    #     with([parent_3.phone_number], 1626093000+7200, 'coucou un super sms')
    #   )

    #   ProgramMessageService.new('2021-07-12', '14:30:00', ["tag.#{tag_2.id}"], 'coucou un super sms').call
    # end
  end

  context 'when no recipients found' do
    it 'returns errors' do
      service = ProgramMessageService.new('2021-07-12', '14:30:00', [], 'coucou').call
      expect(service.errors).to eq(['Tous les champs doivent être complétés.'])
    end
  end

  context 'when no message is given' do
    it 'returns errors' do
      service = ProgramMessageService.new('2021-07-12', '14:30:00', ["parent.#{parent_1.id}"], '').call
      expect(service.errors).to eq(['Tous les champs doivent être complétés.'])
    end
  end

  context 'when no parent numbers found' do
    it 'returns errors' do
      child_1.should_contact_parent1 = false
      service = ProgramMessageService.new('2021-07-12', '14:30:00', ["group.#{group.id}"], 'coucou').call
      expect(service.errors).to eq(['Aucun parent à contacter.'])
    end
  end

end
