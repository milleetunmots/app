require 'rails_helper'

RSpec.describe Child::RejectAiRegistrationsService do
  subject { described_class.new.call }

  def create_child(tag: nil, src_url: nil, group: nil, group_status: nil)
    status = group_status || (group ? 'active' : 'waiting')
    child = FactoryBot.create(:child, group: group, group_status: status, src_url: src_url)
    child.update!(tag_list: [tag]) if tag
    child
  end

  context 'enfant sans cohorte' do
    let!(:child) { create_child(tag: 'utm_source=chatgpt.com') }

    it 'le passe en « Non accompagné »' do
      subject
      expect(child.reload.group_status).to eq 'not_supported'
    end

    it 'le compte parmi les enfants écartés' do
      expect(subject.rejected_children_ids).to include child.id
    end
  end

  context 'enfant dans une cohorte non programmée' do
    let!(:group) { FactoryBot.create(:group, is_programmed: false) }
    let!(:child) { create_child(tag: 'utm_source=chatgpt.com', group: group) }

    it 'le passe en « Non accompagné »' do
      subject
      expect(child.reload.group_status).to eq 'not_supported'
    end

    it 'le détache de sa cohorte' do
      subject
      expect(child.reload.group_id).to be_nil
    end
  end

  # Le test le plus important du lot : un accompagnement déjà démarré ne doit
  # jamais être interrompu par ce job.
  context 'enfant dans une cohorte programmée' do
    let!(:group) { FactoryBot.create(:group, is_programmed: true) }
    let!(:child) { create_child(tag: 'utm_source=chatgpt.com', group: group) }

    it 'ne le touche pas' do
      subject
      expect(child.reload.group_status).to eq 'active'
    end

    it 'le laisse dans sa cohorte' do
      subject
      expect(child.reload.group_id).to eq group.id
    end

    it 'ne le compte pas parmi les enfants écartés' do
      expect(subject.rejected_children_ids).not_to include child.id
    end
  end

  context 'enfant dont utm_source est légitime' do
    let!(:child) { create_child(tag: 'utm_source=caf01') }

    it 'ne le touche pas' do
      subject
      expect(child.reload.group_status).to eq 'waiting'
    end
  end

  context 'enfant sans utm_source' do
    let!(:child) { create_child }

    it 'ne le touche pas' do
      subject
      expect(child.reload.group_status).to eq 'waiting'
    end
  end

  context 'enfant dont seul src_url porte l’information' do
    let!(:child) { create_child(src_url: 'https://1001mots.org/inscription?utm_source=chatgpt.com') }

    it 'le passe en « Non accompagné »' do
      subject
      expect(child.reload.group_status).to eq 'not_supported'
    end
  end

  # Données anciennes : la validation interdit un statut vide aujourd'hui, mais
  # la colonne l'accepte. `where.not` les écarterait silencieusement (NULL en SQL).
  context 'enfant sans statut' do
    let!(:child) do
      create_child(tag: 'utm_source=chatgpt.com').tap { |c| c.update_column(:group_status, nil) }
    end

    it 'le passe en « Non accompagné »' do
      subject
      expect(child.reload.group_status).to eq 'not_supported'
    end
  end

  context 'enfant supprimé' do
    let!(:child) do
      create_child(tag: 'utm_source=chatgpt.com').tap(&:discard)
    end

    it 'ne le touche pas' do
      subject
      expect(child.reload.group_status).to eq 'waiting'
    end

    it 'ne le compte pas parmi les enfants écartés' do
      expect(subject.rejected_children_ids).not_to include child.id
    end
  end

  context 'idempotence' do
    let!(:child) { create_child(tag: 'utm_source=chatgpt.com') }

    it 'ne réécarte pas un enfant déjà écarté au second passage' do
      described_class.new.call
      second_pass = described_class.new.call
      expect(second_pass.rejected_children_ids).to be_empty
    end

    it 'ne lève pas au second passage' do
      described_class.new.call
      expect { described_class.new.call }.not_to raise_error
    end
  end

  context 'traçabilité' do
    let!(:child) { create_child(tag: 'utm_source=chatgpt.com') }

    it 'logue chaque enfant écarté avec son utm_source' do
      allow(Rails.logger).to receive(:info)
      subject
      expect(Rails.logger).to have_received(:info).with(/#{child.id}.*chatgpt\.com/)
    end

    it 'remonte le total du passage dans Rollbar' do
      allow(Rollbar).to receive(:info)
      subject
      expect(Rollbar).to have_received(:info).with(
        'Child::RejectAiRegistrationsService done',
        rejected_children_count: 1,
        rejected_children_ids: [child.id]
      )
    end

    it 'ne remonte rien dans Rollbar quand aucun enfant n’est écarté' do
      described_class.new.call
      allow(Rollbar).to receive(:info)
      described_class.new.call
      expect(Rollbar).not_to have_received(:info)
    end
  end
end
