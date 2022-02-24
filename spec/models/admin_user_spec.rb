# == Schema Information
#
# Table name: admin_users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
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
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

require "rails_helper"

RSpec.describe AdminUser, type: :model do
  subject { FactoryBot.create(:admin_user) }

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
      subject.user_role = "animator"

      expect(subject).to_not be_valid
    end
  end

  describe "#admin?" do
    it "return true if user is super_admin" do
      expect(subject.admin?).to be subject.user_role == "super_admin"
    end
  end

  describe "#team_member?" do
    it "return true if user is team_member" do
      expect(subject.team_member?).to be subject.user_role == "team_member"
    end
  end

  describe "#caller?" do
    it "return true if user is caller" do
      expect(subject.caller?).to be subject.user_role == "caller"
    end
  end
end
