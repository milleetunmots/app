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

  describe "date de naissance" do
    ["/inscription3", "/inscriptioncaf"].each do |path|
      it "est vide à l'ouverture de #{path}" do
        travel_to Date.new(2026, 11, 12)

        visit path

        expect(find("#child_birthdate_3i").value).to eq("")
        expect(find("#child_birthdate_2i").value).to eq("")
        expect(find("#child_birthdate_1i").value).to eq("")
      end
    end
  end
end
