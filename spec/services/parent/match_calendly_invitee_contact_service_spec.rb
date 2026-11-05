require 'rails_helper'

RSpec.describe Parent::MatchCalendlyInviteeContactService do
  def family(supporter:, parent1:, parent2: nil)
    child = FactoryBot.create(:child, parent1: parent1, parent2: parent2)
    child.child_support.update!(supporter: supporter)
    child.child_support
  end

  def match(email:, name:, host: 'https://api.calendly.com/users/AWA')
    described_class.new(host_calendly_user_uri: host, email: email, name: name).call
  end

  describe '#call' do
    context "avec l'accompagnante hôte" do
      it "identifie le parent par son e-mail, sans tenir compte de la casse ni des espaces" do
        awa = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
        mariam = FactoryBot.create(:parent, first_name: 'Mariam', last_name: 'Diallo', email: 'mariam.diallo@example.com')
        family(supporter: awa, parent1: mariam)

        service = match(email: ' Mariam.Diallo@Example.com ', name: 'M. D.')

        expect(service.errors).to be_empty
        expect(service.parent).to eq(mariam)
      end

      it "identifie le parent par prénom et nom quand l'e-mail ne correspond pas" do
        awa = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
        mariam = FactoryBot.create(:parent, first_name: 'Mariam', last_name: 'Diallo', email: 'mariam.diallo@example.com')
        oumar = FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo')
        family(supporter: awa, parent1: mariam, parent2: oumar)

        service = match(email: 'autre@example.com', name: 'Oumar Diallo')

        expect(service.parent).to eq(oumar)
      end

      it "départage par le nom un e-mail partagé par les deux parents" do
        awa = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
        mariam = FactoryBot.create(:parent, first_name: 'Mariam', last_name: 'Diallo', email: 'famille.diallo@example.com')
        oumar = FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo', email: 'famille.diallo@example.com')
        family(supporter: awa, parent1: mariam, parent2: oumar)

        service = match(email: 'famille.diallo@example.com', name: 'Oumar Diallo')

        expect(service.parent).to eq(oumar)
      end

      it "ignore l'e-mail prérempli rdv@1001mots.org" do
        awa = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
        fatou = FactoryBot.create(:parent, first_name: 'Fatou', last_name: 'Sow', email: 'rdv@1001mots.org')
        oumar = FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo')
        family(supporter: awa, parent1: fatou)
        family(supporter: awa, parent1: oumar)

        service = match(email: 'rdv@1001mots.org', name: 'Oumar Diallo')

        expect(service.parent).to eq(oumar)
      end

      it "n'identifie personne quand deux parents portent le même nom" do
        awa = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
        family(supporter: awa, parent1: FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo'))
        family(supporter: awa, parent1: FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo'))

        service = match(email: 'autre@example.com', name: 'Oumar Diallo')

        expect(service.errors).to be_empty
        expect(service.parent).to be_nil
      end

      it 'ignore les parents archivés' do
        awa = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
        oumar = FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo')
        archived = FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo')
        family(supporter: awa, parent1: oumar)
        family(supporter: awa, parent1: archived)
        archived.discard

        service = match(email: 'autre@example.com', name: 'Oumar Diallo')

        expect(service.parent).to eq(oumar)
      end

      it "ignore les familles suivies par une autre accompagnante" do
        FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
        bintou = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/BINTOU')
        aminata = FactoryBot.create(:parent, first_name: 'Aminata', last_name: 'Traoré', email: 'aminata.traore@example.com')
        family(supporter: bintou, parent1: aminata)

        service = match(email: 'aminata.traore@example.com', name: 'Aminata Traoré')

        expect(service.parent).to be_nil
      end

      [
        ['OUMAR DIALLO', true],
        ['Oumâr Diallo', true],
        ['Diallo Oumar', false],
        ['Oumar', false],
        ['', false]
      ].each do |name, matched|
        it "#{matched ? 'reconnaît' : 'ne reconnaît pas'} le nom saisi #{name.inspect}" do
          awa = FactoryBot.create(:admin_user, calendly_user_uri: 'https://api.calendly.com/users/AWA')
          oumar = FactoryBot.create(:parent, first_name: 'Oumar', last_name: 'Diallo')
          family(supporter: awa, parent1: oumar)

          service = match(email: nil, name: name)

          expect(service.parent).to eq(matched ? oumar : nil)
        end
      end
    end

    context "avec un compte Calendly hôte inconnu" do
      it 'renvoie une erreur sans chercher de parent' do
        mariam = FactoryBot.create(:parent, email: 'mariam.diallo@example.com')
        family(supporter: FactoryBot.create(:admin_user), parent1: mariam)

        service = match(email: 'mariam.diallo@example.com', name: nil, host: 'https://api.calendly.com/users/INCONNU')

        expect(service.parent).to be_nil
        expect(service.errors).to eq(
          [{
            message: "Aucune accompagnante n'a ce compte Calendly",
            context: { host_calendly_user_uri: 'https://api.calendly.com/users/INCONNU' }
          }]
        )
      end
    end
  end
end
