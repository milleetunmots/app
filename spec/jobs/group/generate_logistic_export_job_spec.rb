require 'rails_helper'

RSpec.describe Group::GenerateLogisticExportJob do
  describe '#perform' do
    let(:service) { instance_double(Group::GenerateLogisticExportService, call: nil, errors: errors) }

    before do
      allow(Group::GenerateLogisticExportService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(service)
      allow(Rollbar).to receive(:error)
    end

    context "quand l'export échoue" do
      let(:errors) { ['Export logistique en échec : stockage indisponible'] }

      it "rapporte l'erreur à Rollbar" do
        described_class.perform_now

        expect(Rollbar).to have_received(:error).with('Group::GenerateLogisticExportJob', errors: errors)
      end
    end

    context "quand l'export réussit" do
      let(:errors) { [] }

      it "n'envoie rien à Rollbar" do
        described_class.perform_now

        expect(Rollbar).not_to have_received(:error)
      end
    end
  end
end
