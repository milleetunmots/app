# == Schema Information
#
# Table name: admin_users
#
#  id                     :bigint           not null, primary key
#  aircall_phone_number   :string
#  can_send_automatic_sms :boolean          default(TRUE), not null
#  can_treat_task         :boolean          default(FALSE), not null
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  is_disabled            :boolean          default(FALSE)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  user_role              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  aircall_number_id      :bigint
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

require "rails_helper"

RSpec.describe AdminUser, type: :model do
  subject { FactoryBot.create(:admin_user) }

  describe "Validations" do
    let(:valid_user) { FactoryBot.build(:admin_user, password: 'test22398@') }

    context "succeed" do
      it "if the password is valid" do
        expect(valid_user).to be_valid
      end
    end

    context "fail" do
      let(:invalid_user) { FactoryBot.build(:admin_user) }

      it "if the password haven't special characters" do
        invalid_user.password = 'test22398'
        expect(invalid_user).to_not be_valid
      end

      it "if the password haven't 8 characters at least" do
        invalid_user.password = 'te98'
        expect(invalid_user).to_not be_valid
      end

      it "if the password haven't a numeric character" do
        invalid_user.password = 'testspecs'
        expect(invalid_user).to_not be_valid
      end

      it "if the password include common password" do
        invalid_user.password = 'testspecs1001'
        expect(invalid_user).to_not be_valid
      end
    end
  end

  describe "#name" do
    let(:another_user) { FactoryBot.build(:admin_user, name: subject.name) }

    it "is required" do
      subject.name = nil

      expect(subject).to_not be_valid
    end

    it "is unique" do
      expect(another_user).to_not be_valid
    end
  end

  describe "#user_role" do
    it "is required" do
      subject.user_role = nil

      expect(subject).to_not be_valid
    end

    it "is included in ROLES" do
      subject.user_role = "thinker"

      expect(subject).to_not be_valid
    end
  end

  describe "#admin?" do
    it "return true if user is a super_admin" do
      expect(subject.admin?).to be subject.user_role == "super_admin"
    end
  end

  describe "#contributor?" do
    it "return true if user is a contributor" do
      expect(subject.contributor?).to be subject.user_role == "contributor"
    end
  end

  describe "#reader?" do
    it "return true if user is a reader" do
      expect(subject.reader?).to be subject.user_role == "reader"
    end
  end

  describe "#caller?" do
    it "return true if user is a caller" do
      expect(subject.caller?).to be subject.user_role == "caller"
    end
  end

  describe "#animator?" do
    it "return true if user is an animator" do
      expect(subject.animator?).to be subject.user_role == "animator"
    end
  end

  describe ".any_caller_or_animator_with_id?" do
    context 'when a caller with the given id exists' do
      it 'returns true' do
        subject.user_role = 'caller'
        subject.save
        expect(AdminUser.any_caller_or_animator_with_id?(subject.id)).to be_truthy
      end

      it 'returns true' do
        subject.user_role = 'animator'
        subject.save
        expect(AdminUser.any_caller_or_animator_with_id?(subject.id)).to be_truthy
      end
    end

    context 'when no caller with the given id exists' do
      let(:non_existent_id) { 10999 }

      it 'returns false' do
        expect(AdminUser.any_caller_or_animator_with_id?(non_existent_id)).to be_falsey
      end
    end
  end
end
