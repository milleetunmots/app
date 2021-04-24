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
  describe "Validations" do
    context "succeed" do
      it "if the user have a name " do
        expect(FactoryBot.build_stubbed(:admin_user)).to be_valid
      end
    end

    context "fail" do
      it "if the user doesn't have a name" do
        expect(FactoryBot.build_stubbed(:admin_user, name: nil)).to be_invalid
      end

      it "if the user doesn't have a email" do
        expect(FactoryBot.build_stubbed(:admin_user, email: nil)).to be_invalid
      end

      it "if the user already exists" do
        @existing = FactoryBot.create(:admin_user, name:"username")
        expect(FactoryBot.build_stubbed(:admin_user, name: "Username")).to be_invalid
      end
    end
  end
end
