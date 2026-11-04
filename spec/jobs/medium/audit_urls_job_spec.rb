require 'rails_helper'

RSpec.describe Medium::AuditUrlsJob do
  let!(:assignee) { FactoryBot.create(:admin_user, user_role: 'super_admin', email: ENV.fetch('MEDIA_URL_AUDIT_ASSIGNEE_EMAIL')) }
  let!(:operation_project_manager) { FactoryBot.create(:admin_user, email: ENV.fetch('OPERATION_PROJECT_MANAGER_EMAIL')) }
  let(:refused_medium) { FactoryBot.build_stubbed(:medium, name: 'Vidéo', url: 'https://inconnu.example.com/video') }

  before { allow(Rollbar).to receive(:error) }

  context 'when some media would be refused by the url filter' do
    before { allow(Medium).to receive(:refused_by_url_filter).and_return([refused_medium]) }

    it 'assigns the task to the admin of MEDIA_URL_AUDIT_ASSIGNEE_EMAIL' do
      expect { described_class.perform_now }.to change(Task, :count).by(1)

      task = Task.last
      expect(task.assignee).to eq(assignee)
      expect(task.description).to include(refused_medium.url)
    end
  end

  context 'when no medium would be refused' do
    before { allow(Medium).to receive(:refused_by_url_filter).and_return([]) }

    it 'creates no task' do
      expect { described_class.perform_now }.not_to change(Task, :count)
    end
  end
end
