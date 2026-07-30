# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DbSanitizer::Anonymizer do
  subject(:anonymizer) { described_class.new }

  describe '#call' do
    let!(:parent) do
      FactoryBot.create(:parent,
        first_name: 'Cécile', last_name: 'Dupont', letterbox_name: 'Dupont C.',
        phone_number: '0612345678', phone_number_national: '0612345678',
        email: 'cecile.dupont@gmail.com', address: '12 rue des Lilas',
        address_supplement: 'Chez Mme Martin, bât. B',
        city_name: 'Lyon', job: 'Infirmière', aircall_id: 'AC123',
        security_token: 'realtoken', security_code: 'ab'
      )
    end

    let!(:parent_home_without_letterbox) do
      FactoryBot.create(:parent).tap { |p| p.update_columns(letterbox_name: nil, address_supplement: nil) }
    end

    let!(:parent_pmi) do
      FactoryBot.create(:parent, book_delivery_location: 'pmi', book_delivery_organisation_name: 'PMI des Lilas')
                .tap { |p| p.update_columns(letterbox_name: 'Nom Legacy') }
    end

    let!(:child) do
      FactoryBot.create(:child, parent1: parent,
        first_name: 'Emma', last_name: 'Dupont',
        security_code: 'cd', security_token: 'childtoken'
      )
    end

    let!(:child_support) do
      FactoryBot.create(:child_support, current_child: child,
        other_phone_number: '0698765432',
        notes: 'Famille difficile à joindre',
        call1_notes: 'Premier appel réussi'
      )
    end

    let!(:child_support_call_archive) do
      FactoryBot.create(:child_support_call_archive, child_support: child_support,
        call4_notes: 'Appel 4',
        call5_notes: 'Appel 5'
      )
    end

    before { anonymizer.call }

    context 'Parent' do
      subject { parent.reload }

      it 'replaces first_name' do
        expect(subject.first_name).not_to eq('Cécile')
      end

      it 'replaces last_name' do
        expect(subject.last_name).not_to eq('Dupont')
      end

      it 'sets phone_number to safe value' do
        expect(subject.phone_number).to eq('+33800000000')
      end

      it 'sets phone_number_national to safe value' do
        expect(subject.phone_number_national).to eq('+33800000000')
      end

      it 'replaces email with id-based value' do
        expect(subject.email).to eq("parent_#{parent.id}@example.com")
      end

      it 'replaces address' do
        expect(subject.address).not_to eq('12 rue des Lilas')
      end

      it 'replaces address with a realistic street address' do
        expect(subject.address).to match(/\A\d+ /)
      end

      it 'replaces city_name' do
        expect(subject.city_name).not_to eq('Lyon')
      end

      it 'replaces city_name with a realistic city name' do
        expect(subject.city_name).not_to eq('Ville fictive')
      end

      it 'replaces address_supplement with a fake one when present' do
        expect(subject.address_supplement).to be_present
        expect(subject.address_supplement).not_to eq('Chez Mme Martin, bât. B')
      end

      it 'sets letterbox_name to anonymized last_name' do
        expect(subject.letterbox_name).to eq(subject.last_name)
      end

      it 'stays valid' do
        expect(subject).to be_valid
      end

      it 'replaces job' do
        expect(subject.job).not_to eq('Infirmière')
      end

      it 'clears aircall_id' do
        expect(subject.aircall_id).to be_nil
      end

      it 'replaces security_token' do
        expect(subject.security_token).not_to eq('realtoken')
      end
    end

    context 'Parent delivered at home without letterbox_name (legacy data)' do
      subject { parent_home_without_letterbox.reload }

      it 'fills letterbox_name with the anonymized last_name' do
        expect(subject.letterbox_name).to eq(subject.last_name)
      end

      it 'leaves blank address_supplement blank' do
        expect(subject.address_supplement).to be_nil
      end

      it 'stays valid' do
        expect(subject).to be_valid
      end
    end

    context 'Parent delivered to an organisation (pmi)' do
      subject { parent_pmi.reload }

      it 'clears letterbox_name' do
        expect(subject.letterbox_name).to be_nil
      end

      it 'keeps book_delivery_organisation_name' do
        expect(subject.book_delivery_organisation_name).to eq('PMI des Lilas')
      end

      it 'stays valid' do
        expect(subject).to be_valid
      end
    end

    context 'Child' do
      subject { child.reload }

      it 'replaces first_name' do
        expect(subject.first_name).not_to eq('Emma')
      end

      it 'replaces last_name' do
        expect(subject.last_name).not_to eq('Dupont')
      end

      it 'replaces security_code' do
        expect(subject.security_code).not_to eq('cd')
      end

      it 'replaces security_token' do
        expect(subject.security_token).not_to eq('childtoken')
      end
    end

    context 'ChildSupport' do
      subject { child_support.reload }

      it 'sets other_phone_number to safe value' do
        expect(subject.other_phone_number).to eq('+33800000000')
      end

      it 'clears notes' do
        expect(subject.notes).to be_nil
      end

      it 'clears call notes' do
        expect(subject.call1_notes).to be_nil
      end

    end

    context 'ChildSupportCallArchive' do
      subject { child_support_call_archive.reload }

      it 'clears call4 notes' do
        expect(subject.call4_notes).to be_nil
      end

      it 'clears call5 notes' do
        expect(subject.call5_notes).to be_nil
      end
    end
  end
end
