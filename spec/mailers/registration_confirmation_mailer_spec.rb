require "rails_helper"

RSpec.describe RegistrationConfirmationMailer, type: :mailer do
  describe "#confirmation" do
    it "intègre le logo de la charte en pièce jointe inline référencée dans le HTML" do
      child = FactoryBot.create(:child, first_name: "Lina")

      mail = RegistrationConfirmationMailer.confirmation(child.id, "s.dupont@cd93.fr")

      logo = mail.attachments["logo-1001mots.png"]
      expect(logo).to be_present
      expect(logo).to be_inline
      expect(mail.html_part.body.to_s).to include("cid:#{logo.cid}")
      expect(mail.html_part.body.to_s).to include("Inscription confirmée")
    end
  end
end
