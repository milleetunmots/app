require 'rails_helper'

RSpec.describe ActiveAdmin::AdminUsersHelper, type: :helper do
  describe "admin_user_role_select_collection" do
    it "returns the array of arrays consisting of user roles and their french translation" do
      expect(admin_user_role_select_collection).to eq [%w[Administrateur.rice super_admin], ["Membre de l'équipe", "team_member"], %w[Appelant.e caller]]
    end
  end
end
