require 'rails_helper'

RSpec.describe DbSanitizer::AdminSanitizer do
  subject(:sanitizer) { described_class.new }

  let!(:allowed_admin)  { FactoryBot.create(:admin_user, email: 'tech@example.com', is_disabled: false) }
  let!(:other_admin)    { FactoryBot.create(:admin_user, email: 'other@example.com', is_disabled: false) }

  before do
    allow(ENV).to receive(:fetch)
      .with('ADMIN_USERS_ACCOUNTS_WHITELIST', '')
      .and_return('tech@example.com')
    sanitizer.call
  end

  it 'keeps the whitelisted account enabled' do
    expect(allowed_admin.reload.is_disabled).to be(false)
  end

  it 'disables non-whitelisted accounts' do
    expect(other_admin.reload.is_disabled).to be(true)
  end
end
