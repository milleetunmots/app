require 'rails_helper'

RSpec.describe Ability, type: :model do
  actions_sensibles = %i[read_sensitive_information update_sensitive_information update_ok_for_solicitation]
  roles_sans_referente_autorises = %w[super_admin contributor]

  let_it_be(:autre_accompagnante) { FactoryBot.create(:admin_user, user_role: 'caller') }

  describe "droits sur les informations sensibles d'une fiche de suivi" do
    AdminUser::ROLES.each do |role|
      context "pour un utilisateur #{role}" do
        let(:utilisateur) { FactoryBot.create(:admin_user, user_role: role) }
        let(:ability) { Ability.new(utilisateur) }

        context "quand il est la référente de la fiche" do
          let(:fiche) { FactoryBot.build_stubbed(:child_support, supporter: utilisateur) }

          actions_sensibles.each do |action|
            it "peut #{action}" do
              expect(ability.can?(action, fiche)).to be(true)
            end
          end
        end

        context 'quand une autre accompagnante est la référente de la fiche' do
          let(:fiche) { FactoryBot.build_stubbed(:child_support, supporter: autre_accompagnante) }

          actions_sensibles.each do |action|
            it "ne peut pas #{action}" do
              expect(ability.can?(action, fiche)).to be(false)
            end
          end
        end

        context "quand la fiche n'a pas de référente" do
          let(:fiche) { FactoryBot.build_stubbed(:child_support, supporter: nil) }
          autorise = roles_sans_referente_autorises.include?(role)

          actions_sensibles.each do |action|
            it "#{autorise ? 'peut' : 'ne peut pas'} #{action}" do
              expect(ability.can?(action, fiche)).to be(autorise)
            end
          end
        end
      end
    end

    context "quand l'utilisateur est désactivé" do
      it "ne peut rien faire, même en étant la référente" do
        utilisateur = FactoryBot.create(:admin_user, user_role: 'caller', is_disabled: true)
        fiche = FactoryBot.build_stubbed(:child_support, supporter: utilisateur)

        expect(Ability.new(utilisateur).can?(:read_sensitive_information, fiche)).to be(false)
      end
    end

    context "quand la référente de la fiche change" do
      it "retire les droits à l'ancienne référente et les donne à la nouvelle" do
        awa = FactoryBot.create(:admin_user, user_role: 'caller')
        binta = FactoryBot.create(:admin_user, user_role: 'caller')
        fiche = FactoryBot.build_stubbed(:child_support, supporter: awa)

        expect(Ability.new(awa).can?(:read_sensitive_information, fiche)).to be(true)
        expect(Ability.new(binta).can?(:read_sensitive_information, fiche)).to be(false)

        fiche.supporter = binta

        expect(Ability.new(awa).can?(:read_sensitive_information, fiche)).to be(false)
        expect(Ability.new(binta).can?(:read_sensitive_information, fiche)).to be(true)
      end
    end

    context "quand l'utilisateur est un super_admin qui n'est pas la référente" do
      it "garde ses autres droits sur la fiche" do
        super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
        fiche = FactoryBot.build_stubbed(:child_support, supporter: autre_accompagnante)
        ability = Ability.new(super_admin)

        expect(ability.can?(:read, fiche)).to be(true)
        expect(ability.can?(:update, fiche)).to be(true)
        expect(ability.can?(:read_sensitive_information, fiche)).to be(false)
      end
    end

    context "quand l'utilisateur est un contributor qui n'est pas la référente" do
      it "peut toujours modifier les autres champs de la fiche" do
        contributor = FactoryBot.create(:admin_user, user_role: 'contributor')
        fiche = FactoryBot.build_stubbed(:child_support, supporter: autre_accompagnante)

        expect(Ability.new(contributor).can?(:update, fiche)).to be(true)
      end
    end
  end
end
