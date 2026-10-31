require 'rails_helper'

RSpec.describe Group::GenerateLogisticExportService do
  describe '#call' do
    subject(:service) { described_class.new }

    let!(:group) { create_group }
    let!(:book) { FactoryBot.create(:book) }
    let!(:support_module) { FactoryBot.create(:support_module, book: book) }
    let!(:shippable_module) { create_module(group) }
    let!(:unshippable_module) { create_module(group, address_suspected: true) }
    let(:scheduled_jobs) { [scheduled_sms_job(group, at: 4.days.from_now)] }

    before { allow(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled_jobs) }

    # le job d'export ne retient que les cohortes dont un ProgramSupportModuleSmsJob est programmé dans la semaine
    def scheduled_sms_job(group, at:)
      instance_double(
        Sidekiq::SortedEntry,
        at: at,
        args: [{ 'job_class' => 'ChildrenSupportModule::ProgramSupportModuleSmsJob', 'arguments' => [group.id, '09-11-2026'] }]
      )
    end

    # deux modules déjà programmés : le prochain est le module d'index 3
    def create_group
      FactoryBot.create(:group).tap { |group| group.update_column(:support_module_programmed, 2) }
    end

    def create_module(group, address_suspected: false, support_module: self.support_module)
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      child.child_support.update_column(:address_suspected_invalid_at, Time.zone.now) if address_suspected
      FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
    end

    it 'enregistre le LogisticExport et fige les livres' do
      expect { service.call }.to change(LogisticExport, :count).by(1)

      expect(service.errors).to be_empty
      expect(shippable_module.reload[:book_id]).to eq(book.id)
      expect(shippable_module.book_condition).to be_nil
      expect(unshippable_module.reload[:book_id]).to eq(book.id)
      expect(unshippable_module.book_condition).to eq('not_sent')
    end

    {
      6.days + 23.hours => true,
      7.days + 1.hour => false
    }.each do |delay, frozen|
      context "quand le SMS du module est programmé dans #{delay.inspect}" do
        let(:scheduled_jobs) { [scheduled_sms_job(group, at: delay.from_now)] }

        it(frozen ? 'fige les livres' : 'ne fige pas les livres') do
          service.call

          expect(shippable_module.reload[:book_id]).to eq(frozen ? book.id : nil)
        end
      end
    end

    context "quand le choix d'un module manque dans une cohorte" do
      let!(:incomplete_group) { create_group }
      let!(:incomplete_module) { create_module(incomplete_group) }
      let!(:missing_choice_module) { create_module(incomplete_group, support_module: nil) }
      let(:scheduled_jobs) do
        [scheduled_sms_job(group, at: 4.days.from_now), scheduled_sms_job(incomplete_group, at: 4.days.from_now)]
      end

      before { FactoryBot.create(:admin_user, email: ENV.fetch('OPERATION_PROJECT_MANAGER_EMAIL')) }

      it 'ne fige pas les livres de cette cohorte' do
        service.call

        expect(incomplete_module.reload[:book_id]).to be_nil
      end

      it 'fige les livres des autres cohortes' do
        service.call

        expect(shippable_module.reload[:book_id]).to eq(book.id)
      end

      it 'crée une tâche pour la logistique et signale la cohorte' do
        expect { service.call }.to change(Task.where(title: 'Choix de modules incomplets — export YLS logistique incomplet'), :count).by(1)

        expect(service.errors).to include("Cohortes avec des modules sans choix : #{incomplete_group.name}")
      end
    end

    context "quand l'enregistrement du LogisticExport échoue" do
      before do
        allow_any_instance_of(LogisticExport).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError, 'stockage indisponible')
      end

      it "remonte l'erreur et ne fige aucun livre" do
        service.call

        expect(service.errors).to include('Export logistique en échec : stockage indisponible')
        expect(shippable_module.reload[:book_id]).to be_nil
      end
    end
  end
end
