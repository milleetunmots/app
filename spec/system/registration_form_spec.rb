require "rails_helper"

RSpec.describe "Formulaire d'inscription", type: :system do
  before { driven_by :rack_test }

  context "sur le formulaire PMI" do
    it "affiche le formulaire et le bouton Valider" do
      visit "/inscription3"

      expect(page).to have_css("form#new_child")
      expect(page).to have_button("Valider")
    end
  end
end
