require "rails_helper"

RSpec.describe AdminUserDecorator do
  subject { FactoryBot.build(:admin_user, email: "user@mail.co", user_role: "team_member") }

  describe "#email_link" do
    it "returns the admin user's email link" do
      expect(subject.decorate.email_link).to eq "<a href=\"mailto:user@mail.co\">user@mail.co</a>"
    end
  end

  describe "#user_role" do
    it "returns the user role translation into french" do
      expect(subject.decorate.user_role).to eq "Membre de l'équipe"
    end
  end
end
