require 'rails_helper'
require 'rake'

RSpec.describe 'sidekiq:purge_before_first_call_message_jobs' do
  before(:all) do
    Rake.application.rake_require('tasks/purge_before_first_call_message_jobs', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['sidekiq:purge_before_first_call_message_jobs'] }
  let(:old_job_class) { 'Parent::SendBeforeFirstCallMessageJob' }

  def job_entry(job_class)
    instance_double(Sidekiq::SortedEntry, args: [{ 'job_class' => job_class }], delete: true)
  end

  let(:scheduled_old_job) { job_entry(old_job_class) }
  let(:scheduled_other_job) { job_entry('Parent::SendBeforeCallsMessageDailyJob') }
  let(:retry_old_job) { job_entry(old_job_class) }
  let(:dead_old_job) { job_entry(old_job_class) }

  before do
    task.reenable
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return([scheduled_old_job, scheduled_other_job])
    allow(Sidekiq::RetrySet).to receive(:new).and_return([retry_old_job])
    allow(Sidekiq::DeadSet).to receive(:new).and_return([dead_old_job])
  end

  context 'hors production' do
    it "refuse de s'exécuter et ne supprime aucun job" do
      expect { task.invoke('apply') }.to raise_error(SystemExit).and output(/production/).to_stderr

      expect(scheduled_old_job).not_to have_received(:delete)
    end
  end

  context 'en production' do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

    it 'ne supprime rien en dry-run et annonce le nombre de jobs trouvés' do
      expect { task.invoke }.to output(/DRY-RUN.*planifiés : 1.*en retry : 1.*morts : 1/m).to_stdout

      [scheduled_old_job, retry_old_job, dead_old_job].each do |entry|
        expect(entry).not_to have_received(:delete)
      end
    end

    it "supprime les jobs d'ancien SMS planifiés, en retry et morts, avec l'argument apply" do
      expect { task.invoke('apply') }.to output(/planifiés : 1.*en retry : 1.*morts : 1/m).to_stdout

      [scheduled_old_job, retry_old_job, dead_old_job].each do |entry|
        expect(entry).to have_received(:delete).once
      end
    end

    it 'ne touche pas aux autres jobs planifiés' do
      task.invoke('apply')

      expect(scheduled_other_job).not_to have_received(:delete)
    end

    it "est idempotente : une seconde exécution sans job restant n'échoue pas et ne supprime rien" do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([scheduled_other_job])
      allow(Sidekiq::RetrySet).to receive(:new).and_return([])
      allow(Sidekiq::DeadSet).to receive(:new).and_return([])

      expect { task.invoke('apply') }.to output(/planifiés : 0.*en retry : 0.*morts : 0/m).to_stdout
      expect(scheduled_other_job).not_to have_received(:delete)
    end
  end
end
