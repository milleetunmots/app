require 'rails_helper'

RSpec.describe ProgramMessageService do

  let_it_be(:parent_1, reload: true) { FactoryBot.create(:parent, first_name: 'Sami') }
  let_it_be(:parent_2, reload: true) { FactoryBot.create(:parent, phone_number: '', first_name: 'Fabien') }
  let_it_be(:parent_3, reload: true) { FactoryBot.create(:parent, first_name: 'Aristide') }
    
  let_it_be(:tag_1, reload: true) { FactoryBot.create(:tag, parent1_id: 'cbfd') }
  let_it_be(:tag_2, reload: true) { FactoryBot.create(:tag, name: 'good') }

  let_it_be(:tagging_1, reload: true) { FactoryBot.create(:tagging, tag_id: tag_1.id, taggable_id: parent_1.id) }
  let_it_be(:tagging_2, reload: true) { FactoryBot.create(:tagging, tag_id: tag_2.id, taggable_id: parent_3.id) }

  let_it_be(:group, reload: true) { FactoryBot.create(:group, name: 'Groupe des minimoys') }
  
  let_it_be(:child_1, reload: true) { FactoryBot.create(
    :child, 
    should_contact_parent1: true, 
    parent1_id: parent_2.id, 
    group_id: group.id, 
    first_name: 'Kevin'
  )}

  context 'valid' do
    it 'valid data for sending' do
      expect(SpotHit::SendSmsService).to(
        receive(:initialize).
        with([parent_3.phone_number], DateTime.now, "coucou un super sms")
      )

      ProgramMessageService.new(tag_2).call
    end
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
      service = ProgramMessageService.new('2021-07-12', '14:30:00', ["group.#{group.id}"], 'coucou').call
      expect(service.errors).to eq(['Aucun parent à contacter.'])
    end
  end

end
