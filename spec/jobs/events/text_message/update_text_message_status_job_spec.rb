require 'rails_helper'

RSpec.describe Events::TextMessage::UpdateTextMessageStatusJob, type: :job do
  subject { described_class }

  describe '#perform_later' do
    it 'enqueues the job on the low priority queue' do
      ActiveJob::Base.queue_adapter = :test
      expect {
        subject.perform_later('message-id', 'status')
      }.to have_enqueued_job(described_class).on_queue('low').exactly(:once)
    end
  end
end
