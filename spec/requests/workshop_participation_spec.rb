require "rails_helper"

RSpec.describe WorkshopParticipationController, type: :request do
  describe "#edit" do
    it "propose Oui et Non avec la nouvelle charte quand l'atelier a un seul créneau" do
      workshop = FactoryBot.create(:workshop, first_workshop_time_slot: Time.zone.parse("2026-12-05 10:00"), second_workshop_time_slot: nil)
      participation = FactoryBot.create(:workshop_participation, workshop: workshop)

      get "/w/#{participation.related.security_token}/#{workshop.id}"
      page = Capybara.string(response.body)

      expect(page.find(".charter-page #mots-logo")[:src]).to include("registration/logo-1001mots")
      expect(page.find(".charter-page h1")).to have_text("Allez-vous participer à l'atelier")
      expect(page.find(".charter-page-body")).to have_button("Oui")
      expect(page.find(".charter-page-body")).to have_button("Non")
    end

    it "propose chaque créneau et le refus quand l'atelier a deux créneaux" do
      workshop = FactoryBot.create(
        :workshop,
        workshop_date: Date.new(2026, 12, 5),
        first_workshop_time_slot: Time.zone.parse("2026-12-05 10:00"),
        second_workshop_time_slot: Time.zone.parse("2026-12-05 14:30")
      )
      participation = FactoryBot.create(:workshop_participation, workshop: workshop)

      get "/w/#{participation.related.security_token}/#{workshop.id}"
      page = Capybara.string(response.body)

      expect(page.find(".charter-page h1")).to have_text("A quel créneau de l'atelier du 05/12/2026 souhaitez-vous participer ?")
      expect(page.find(".charter-page-body")).to have_button("10h00")
      expect(page.find(".charter-page-body")).to have_button("14h30")
      expect(page.find(".charter-page-body")).to have_button("Refuser l'atelier")
    end
  end

  describe "#updated" do
    it "remercie avec la nouvelle charte" do
      get "/mis-a-jour-invitation"
      page = Capybara.string(response.body)

      expect(page.find(".charter-page h1")).to have_text("Merci pour votre réponse")
    end
  end
end
