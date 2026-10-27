require 'rails_helper'

RSpec.describe Ability, type: :model do
  actions_sensibles = %i[read_sensitive_information update_sensitive_information update_ok_for_solicitation]

  let_it_be(:autre_accompagnante) { FactoryBot.create(:admin_user, user_role: 'caller') }

  describe "droits sur les informations sensibles d'une fiche de suivi" do
    AdminUser::ROLES.each do |role|
      context "pour un utilisateur #{role}" do
        let(:utilisateur) { FactoryBot.create(:admin_user, user_role: role) }
        let(:ability) { Ability.new(utilisateur) }

        # un reader n'est jamais référent d'une fiche
        unless role == 'reader'
          context "quand il est la référente de la fiche" do
            let(:fiche) { FactoryBot.build_stubbed(:child_support, supporter: utilisateur) }

            actions_sensibles.each do |action|
              it "peut #{action}" do
                expect(ability.can?(action, fiche)).to be(true)
              end
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

          actions_sensibles.each do |action|
            it "ne peut pas #{action}" do
              expect(ability.can?(action, fiche)).to be(false)
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

  describe "droit de changer le supporter d'une fiche de suivi" do
    let(:fiche) { FactoryBot.build_stubbed(:child_support, supporter: autre_accompagnante) }

    def ability_avec_liste(utilisateur, liste)
      stub_const('ENV', ENV.to_h.merge('SUPPORTER_ASSIGNMENT_EMAILS' => liste))
      Ability.new(utilisateur)
    end

    context "pour un super_admin" do
      let(:super_admin) { FactoryBot.create(:admin_user, user_role: 'super_admin') }

      it "peut, même quand la liste est vide" do
        expect(ability_avec_liste(super_admin, '').can?(:assign_supporter, fiche)).to be(true)
      end

      it "peut, même quand la variable n'est pas définie" do
        stub_const('ENV', ENV.to_h.except('SUPPORTER_ASSIGNMENT_EMAILS'))

        expect(Ability.new(super_admin).can?(:assign_supporter, fiche)).to be(true)
      end
    end

    context "pour un contributor" do
      let(:contributor) { FactoryBot.create(:admin_user, user_role: 'contributor', email: 'camille@1001mots.org') }

      it "peut quand son e-mail est dans la liste" do
        expect(ability_avec_liste(contributor, 'camille@1001mots.org').can?(:assign_supporter, fiche)).to be(true)
      end

      it "peut quand son e-mail est l'un de plusieurs e-mails de la liste" do
        liste = 'autre@1001mots.org camille@1001mots.org dernier@1001mots.org'

        expect(ability_avec_liste(contributor, liste).can?(:assign_supporter, fiche)).to be(true)
      end

      it "peut quand la casse de l'e-mail diffère de celle de la liste" do
        expect(ability_avec_liste(contributor, 'CAMILLE@1001mots.ORG').can?(:assign_supporter, fiche)).to be(true)
      end

      it "ne peut pas quand son e-mail n'est pas dans la liste" do
        expect(ability_avec_liste(contributor, 'autre@1001mots.org').can?(:assign_supporter, fiche)).to be(false)
      end

      it "ne peut pas quand la liste est vide" do
        expect(ability_avec_liste(contributor, '').can?(:assign_supporter, fiche)).to be(false)
      end

      it "ne peut pas quand la variable n'est pas définie" do
        stub_const('ENV', ENV.to_h.except('SUPPORTER_ASSIGNMENT_EMAILS'))

        expect(Ability.new(contributor).can?(:assign_supporter, fiche)).to be(false)
      end

      it "ne peut pas quand son e-mail n'est qu'une partie d'un e-mail listé" do
        expect(ability_avec_liste(contributor, 'camille@1001mots.org.fr').can?(:assign_supporter, fiche)).to be(false)
      end

      it "ne peut pas quand il est désactivé, même listé" do
        contributor.update!(is_disabled: true)

        expect(ability_avec_liste(contributor, 'camille@1001mots.org').can?(:assign_supporter, fiche)).to be(false)
      end
    end

    %w[reader animator caller].each do |role|
      context "pour un #{role}" do
        let(:utilisateur) { FactoryBot.create(:admin_user, user_role: role, email: 'camille@1001mots.org') }

        it "ne peut pas, même quand son e-mail est dans la liste" do
          expect(ability_avec_liste(utilisateur, 'camille@1001mots.org').can?(:assign_supporter, fiche)).to be(false)
        end
      end
    end

    context "pour la supporter actuelle de la fiche" do
      it "ne peut pas changer le supporter de sa propre fiche" do
        awa = FactoryBot.create(:admin_user, user_role: 'caller', email: 'awa@1001mots.org')
        sa_fiche = FactoryBot.build_stubbed(:child_support, supporter: awa)

        expect(ability_avec_liste(awa, 'awa@1001mots.org').can?(:assign_supporter, sa_fiche)).to be(false)
      end
    end
  end

  describe "droit de rattacher un enfant à un parent (link_child)" do
    let(:utilisateur_id) { FactoryBot.create(:admin_user, user_role: 'caller').id }
    let(:parent_cible) { FactoryBot.create(:parent) }

    def avec_fiche_suivie_par(supporter)
      FactoryBot.create(:child, parent1: parent_cible).tap { |enfant| enfant.child_support.update!(supporter: supporter) }
    end

    %w[caller animator].each do |role|
      context "pour un #{role}" do
        let(:utilisateur) { FactoryBot.create(:admin_user, user_role: role) }
        let(:ability) { Ability.new(utilisateur) }

        it "peut rattacher un enfant à un parent qui n'a encore aucun enfant" do
          expect(ability.can?(:link_child, parent_cible)).to be(true)
        end

        it "peut rattacher un enfant à un parent dont toutes les fiches suivies sont les siennes" do
          avec_fiche_suivie_par(utilisateur)

          expect(ability.can?(:link_child, parent_cible)).to be(true)
        end

        it "ne peut pas rattacher un enfant à un parent dont la fiche est suivie par quelqu'un d'autre" do
          avec_fiche_suivie_par(autre_accompagnante)

          expect(ability.can?(:link_child, parent_cible)).to be(false)
        end

        it "ne peut pas rattacher un enfant à un parent dont la fiche n'a pas de supporter" do
          avec_fiche_suivie_par(nil)

          expect(ability.can?(:link_child, parent_cible)).to be(false)
        end

        it "ne peut pas rattacher un enfant à un parent dont une seule des fiches est suivie par quelqu'un d'autre" do
          avec_fiche_suivie_par(utilisateur)
          avec_fiche_suivie_par(autre_accompagnante)

          expect(ability.can?(:link_child, parent_cible)).to be(false)
        end

        it "ignore les enfants archivés du parent" do
          avec_fiche_suivie_par(autre_accompagnante).discard

          expect(ability.can?(:link_child, parent_cible)).to be(true)
        end
      end
    end

    %w[super_admin contributor reader].each do |role|
      it "reste autorisé pour un #{role}, même sur la famille d'un autre" do
        avec_fiche_suivie_par(autre_accompagnante)

        expect(Ability.new(FactoryBot.create(:admin_user, user_role: role)).can?(:link_child, parent_cible)).to be(true)
      end
    end
  end

  describe "simulation de connexion (impersonate)" do
    let(:accompagnante) { FactoryBot.create(:admin_user, user_role: 'caller') }

    it 'est réservée aux super admins' do
      expect(Ability.new(FactoryBot.create(:admin_user, user_role: 'super_admin')).can?(:impersonate, accompagnante)).to be(true)

      (AdminUser::ROLES - %w[super_admin]).each do |role|
        expect(Ability.new(FactoryBot.create(:admin_user, user_role: role)).can?(:impersonate, accompagnante)).to be(false)
      end
    end

    it "ne vise ni un super admin ni un compte désactivé" do
      ability = Ability.new(FactoryBot.create(:admin_user, user_role: 'super_admin'))

      expect(ability.can?(:impersonate, FactoryBot.build_stubbed(:admin_user, user_role: 'super_admin'))).to be(false)
      expect(ability.can?(:impersonate, FactoryBot.build_stubbed(:admin_user, user_role: 'caller', is_disabled: true))).to be(false)
    end

    describe 'en lecture seule' do
      let(:contributrice) { FactoryBot.create(:admin_user, user_role: 'contributor') }
      let(:ability) { Ability.new(contributrice, read_only: true) }
      let(:group) { FactoryBot.build_stubbed(:group) }

      it 'garde la consultation et l’affichage des formulaires' do
        expect(ability.can?(:read, group)).to be(true)
        expect(ability.can?(:edit, group)).to be(true)
      end

      it 'retire les actions custom et les suppressions' do
        expect(ability.can?(:program, group)).to be(false)
        expect(ability.can?(:destroy, group)).to be(false)
        expect(ability.can?(:create, Group)).to be(false)
      end

      it "ne donne rien que le compte simulé n'a pas" do
        expect(Ability.new(accompagnante, read_only: true).can?(:read, group)).to be(false)
      end
    end
  end

  describe "droits sur la tâche de suivi d'un envoi bloqué" do
    actions_interdites = %i[update destroy discard]

    let(:attempt) { FactoryBot.build_stubbed(:blocked_send_attempt) }

    %w[contributor reader caller animator].each do |role|
      context "pour un utilisateur #{role}, auteur de l'envoi" do
        let(:auteur) { FactoryBot.create(:admin_user, user_role: role) }
        let(:ability) { Ability.new(auteur) }
        let(:tache) { FactoryBot.build_stubbed(:task, reporter: auteur, related: attempt) }

        it 'peut la lire' do
          expect(ability.can?(:read, tache)).to be(true)
        end

        actions_interdites.each do |action|
          it "ne peut pas #{action}" do
            expect(ability.can?(action, tache)).to be(false)
          end
        end

        it 'garde la main sur ses autres tâches' do
          autre_tache = FactoryBot.build_stubbed(:task, reporter: auteur, related: FactoryBot.build_stubbed(:parent))

          expect(ability.can?(:update, autre_tache)).to be(true)
        end
      end
    end

    it 'peut être modifiée par un super_admin' do
      super_admin = FactoryBot.create(:admin_user, user_role: 'super_admin')
      tache = FactoryBot.build_stubbed(:task, related: attempt)

      expect(Ability.new(super_admin).can?(:update, tache)).to be(true)
    end
  end
end
