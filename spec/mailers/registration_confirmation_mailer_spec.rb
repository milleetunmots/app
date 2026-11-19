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

    # L'image Docker de staging et de production (Dockerfile.release) supprime
    # app/assets après la précompilation : le logo n'existe plus qu'en version
    # précompilée, retrouvée par le manifeste Sprockets.
    it "trouve le logo précompilé quand les sources d'app/assets ont été supprimées" do
      child = FactoryBot.create(:child, first_name: "Lina")
      compiled_logo = "precompiled logo bytes".b

      Dir.mktmpdir do |root|
        assets_dir = File.join(root, "public/assets")
        FileUtils.mkdir_p(File.join(assets_dir, "registration"))
        File.binwrite(File.join(assets_dir, "registration/logo-1001mots-0123abcd.png"), compiled_logo)
        File.write(
          File.join(assets_dir, ".sprockets-manifest-#{SecureRandom.hex(16)}.json"),
          { files: {}, assets: { "registration/logo-1001mots.png" => "registration/logo-1001mots-0123abcd.png" } }.to_json
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(root))
        allow(Rails.application).to receive(:assets_manifest).and_return(Sprockets::Manifest.new(nil, assets_dir))

        mail = RegistrationConfirmationMailer.confirmation(child.id, "s.dupont@cd93.fr")

        expect(mail.attachments["logo-1001mots.png"].body.decoded).to eq(compiled_logo)
      end
    end
  end
end
