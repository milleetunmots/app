require "rails_helper"

RSpec.describe Admin::AdminUsersController, type: :request do
  describe "DELETE /destroy" do
    subject { FactoryBot.create(:admin_user) }

    context "if the user hasn't tasks assigned" do
      it "redirect to admin_users index with alert" do

      end


    end
  end
end
