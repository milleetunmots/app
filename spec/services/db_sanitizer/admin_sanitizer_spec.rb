require 'rails_helper'

RSpec.describe DbSanitizer::AdminSanitizer do
  subject(:sanitizer) { described_class.new }

  let!(:allowed_admin) do
    FactoryBot.create(
      :admin_user,
      email: 'tech@example.com',
      is_disabled: false,
      phone_number: '0612345678',
      two_factor_enabled: true
    ).tap do |admin_user|
      admin_user.generate_otp!
      admin_user.update!(remember_created_at: 1.day.ago)
    end
  end
  let!(:other_admin) do
    FactoryBot.create(
      :admin_user,
      email: 'other@example.com',
      is_disabled: false,
      phone_number: '0698765432',
      two_factor_enabled: true
    ).tap(&:generate_otp!)
  end

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

  it 'removes all personal phone numbers and disables two-factor authentication' do
    expect(AdminUser.where.not(phone_number: nil)).to be_empty
    expect(AdminUser.where(two_factor_enabled: true)).to be_empty
  end

  it 'clears pending OTP and remembered-session data, including for whitelisted accounts' do
    expect(allowed_admin.reload).to have_attributes(
      otp_code_digest: nil,
      otp_sent_at: nil,
      otp_attempts: 0,
      remember_created_at: nil
    )
  end
end
