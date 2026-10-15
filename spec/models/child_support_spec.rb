# == Schema Information
#
# Table name: child_supports
#
#  id                                         :bigint           not null, primary key
#  address_suspected_invalid_at               :datetime
#  already_working_with                       :boolean
#  availability                               :string
#  book_not_received                          :string
#  books_quantity                             :string
#  calendly_booking_url                       :string
#  call0_attempt                              :string
#  call0_duration                             :integer
#  call0_goal_sent                            :string
#  call0_goals                                :text
#  call0_goals_sms                            :text
#  call0_language_awareness                   :string
#  call0_language_development                 :text
#  call0_notes                                :text
#  call0_parent_actions                       :text
#  call0_parent_progress                      :string
#  call0_reading_frequency                    :string
#  call0_review                               :string
#  call0_sendings_benefits                    :string
#  call0_sendings_benefits_details            :text
#  call0_status                               :string
#  call0_status_details                       :text
#  call0_talk_needed                          :boolean          default(FALSE), not null
#  call0_technical_information                :text
#  call0_tv_frequency                         :string
#  call0_why_talk_needed                      :text
#  call1_attempt                              :string
#  call1_avoid_disengagement_date             :datetime
#  call1_avoid_disengagement_details          :text
#  call1_duration                             :integer
#  call1_family_progress                      :string
#  call1_goals                                :text
#  call1_goals_sms                            :text
#  call1_goals_tracking                       :text
#  call1_language_awareness                   :string
#  call1_language_development                 :text
#  call1_notes                                :text
#  call1_parent_actions                       :text
#  call1_parent_progress                      :string
#  call1_previous_goals_follow_up             :string
#  call1_reading_frequency                    :string
#  call1_review                               :string
#  call1_sendings_benefits                    :string
#  call1_sendings_benefits_details            :text
#  call1_status                               :string
#  call1_status_details                       :text
#  call1_talk_needed                          :boolean          default(FALSE), not null
#  call1_technical_information                :text
#  call1_tv_frequency                         :string
#  call1_why_talk_needed                      :text
#  call2_attempt                              :string
#  call2_avoid_disengagement_date             :datetime
#  call2_avoid_disengagement_details          :text
#  call2_duration                             :integer
#  call2_family_progress                      :string
#  call2_goals                                :text
#  call2_goals_sms                            :text
#  call2_goals_tracking                       :text
#  call2_language_awareness                   :string
#  call2_language_development                 :text
#  call2_notes                                :text
#  call2_parent_actions                       :text
#  call2_parent_progress                      :string
#  call2_previous_goals_follow_up             :string
#  call2_reading_frequency                    :string
#  call2_review                               :string
#  call2_sendings_benefits                    :string
#  call2_sendings_benefits_details            :text
#  call2_status                               :string
#  call2_status_details                       :text
#  call2_talk_needed                          :boolean          default(FALSE), not null
#  call2_technical_information                :text
#  call2_tv_frequency                         :string
#  call2_why_talk_needed                      :text
#  call3_attempt                              :string
#  call3_avoid_disengagement_date             :datetime
#  call3_avoid_disengagement_details          :text
#  call3_duration                             :integer
#  call3_goals                                :text
#  call3_goals_sms                            :text
#  call3_goals_tracking                       :text
#  call3_language_awareness                   :string
#  call3_language_development                 :text
#  call3_notes                                :text
#  call3_parent_actions                       :text
#  call3_parent_progress                      :string
#  call3_previous_goals_follow_up             :string
#  call3_reading_frequency                    :string
#  call3_review                               :string
#  call3_sendings_benefits                    :string
#  call3_sendings_benefits_details            :text
#  call3_status                               :string
#  call3_status_details                       :text
#  call3_talk_needed                          :boolean          default(FALSE), not null
#  call3_technical_information                :text
#  call3_tv_frequency                         :string
#  call3_why_talk_needed                      :text
#  call_infos                                 :string
#  call_recording_consent                     :string
#  child_count                                :integer
#  discarded_at                               :datetime
#  enrollment_reasons                         :string           default([]), is an Array
#  family_support_should_be_stopped           :string
#  has_important_information_parental_consent :boolean          default(FALSE), not null
#  important_information                      :text
#  instagram_follower                         :string
#  instagram_user                             :string
#  is_bilingual                               :string           default("2_no_information")
#  most_present_parent                        :string
#  notes                                      :text
#  ok_for_solicitation                        :boolean
#  other_phone_number                         :string
#  parent1_available_support_module_list      :string           is an Array
#  parent2_available_support_module_list      :string           is an Array
#  parent_mid_term_rate                       :integer
#  parent_mid_term_reaction                   :string
#  parent_needs                               :text
#  restart_support_date                       :datetime
#  restart_support_details                    :text
#  second_language                            :string
#  sensitive_information                      :text
#  stop_support_date                          :datetime
#  stop_support_details                       :text
#  stop_support_reason                        :string
#  suggested_videos_counter                   :jsonb            is an Array
#  support_stopped_for_unassigned_number_at   :datetime
#  to_call                                    :boolean
#  unassigned_number_reactivated_at           :datetime
#  will_stay_in_group                         :boolean          default(FALSE), not null
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  module2_chosen_by_parents_id               :bigint
#  module3_chosen_by_parents_id               :bigint
#  module4_chosen_by_parents_id               :bigint
#  module5_chosen_by_parents_id               :bigint
#  module6_chosen_by_parents_id               :bigint
#  restart_support_caller_id                  :bigint
#  stop_support_caller_id                     :bigint
#  supporter_id                               :bigint
#
# Indexes
#
#  index_child_supports_on_book_not_received                      (book_not_received)
#  index_child_supports_on_call0_parent_progress                  (call0_parent_progress)
#  index_child_supports_on_call0_reading_frequency                (call0_reading_frequency)
#  index_child_supports_on_call0_tv_frequency                     (call0_tv_frequency)
#  index_child_supports_on_call1_parent_progress                  (call1_parent_progress)
#  index_child_supports_on_call1_reading_frequency                (call1_reading_frequency)
#  index_child_supports_on_call1_tv_frequency                     (call1_tv_frequency)
#  index_child_supports_on_call2_language_awareness               (call2_language_awareness)
#  index_child_supports_on_call2_parent_progress                  (call2_parent_progress)
#  index_child_supports_on_call3_language_awareness               (call3_language_awareness)
#  index_child_supports_on_call3_parent_progress                  (call3_parent_progress)
#  index_child_supports_on_discarded_at                           (discarded_at)
#  index_child_supports_on_module2_chosen_by_parents_id           (module2_chosen_by_parents_id)
#  index_child_supports_on_module3_chosen_by_parents_id           (module3_chosen_by_parents_id)
#  index_child_supports_on_module4_chosen_by_parents_id           (module4_chosen_by_parents_id)
#  index_child_supports_on_module5_chosen_by_parents_id           (module5_chosen_by_parents_id)
#  index_child_supports_on_module6_chosen_by_parents_id           (module6_chosen_by_parents_id)
#  index_child_supports_on_parent1_available_support_module_list  (parent1_available_support_module_list) USING gin
#  index_child_supports_on_parent2_available_support_module_list  (parent2_available_support_module_list) USING gin
#  index_child_supports_on_restart_support_caller_id              (restart_support_caller_id)
#  index_child_supports_on_stop_support_caller_id                 (stop_support_caller_id)
#  index_child_supports_on_supporter_id                           (supporter_id)
#
# Foreign Keys
#
#  fk_rails_...  (module2_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module3_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module4_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module5_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (module6_chosen_by_parents_id => support_modules.id)
#  fk_rails_...  (restart_support_caller_id => admin_users.id)
#  fk_rails_...  (stop_support_caller_id => admin_users.id)
#  fk_rails_...  (supporter_id => admin_users.id)
#

require "rails_helper"

RSpec.describe ChildSupport, type: :model do
  let_it_be(:first_parent, reload: true) { FactoryBot.create(:parent, postal_code: 75006) }
  let_it_be(:second_parent, reload: true) { FactoryBot.create(:parent, postal_code: 99999) }
  let_it_be(:third_parent, reload: true) { FactoryBot.create(:parent, postal_code: 88888) }
  let_it_be(:fourth_parent, reload: true) { FactoryBot.create(:parent, postal_code: 55555) }

  let_it_be(:admin_user, reload: true) { FactoryBot.create(:admin_user) }

  let_it_be(:group, reload: true) { FactoryBot.create(:group) }

  let!(:first_child) { FactoryBot.create(:child, parent1: first_parent, parent2: third_parent, group: group, group_status: "active") }
  let!(:second_child) { FactoryBot.create(:child, parent1: second_parent, parent2: fourth_parent, group: group, group_status: "active") }
  let!(:third_child) { FactoryBot.create(:child, parent1: first_parent, group: group, group_status: "paused") }

  let!(:first_child_support) { FactoryBot.create(:child_support, current_child: first_child, supporter: admin_user) }
  let!(:second_child_support) { second_child.child_support }
  let!(:third_child_support) { third_child.child_support }

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:child_support)).to be_valid
      end

      (0..3).each do |call_idx|
        it "if call#{call_idx}_language_awareness is provided by child_support::LANGUAGE_AWARENESS" do
          expect(FactoryBot.build_stubbed(:child_support, "call#{call_idx}_language_awareness": ChildSupport::LANGUAGE_AWARENESS.sample)).to be_valid
        end

        it "if call#{call_idx}_parent_progress is provided by child_support::PARENT_PROGRESS" do
          expect(FactoryBot.build_stubbed(:child_support, "call#{call_idx}_parent_progress": ChildSupport::PARENT_PROGRESS.sample)).to be_valid
        end

        it "if call#{call_idx}_sendings_benefits is provided by child_support::SENDINGS_BENEFITS" do
          expect(FactoryBot.build_stubbed(:child_support, "call#{call_idx}_sendings_benefits": ChildSupport::SENDINGS_BENEFITS.sample)).to be_valid
        end
      end
    end
  end

  describe "#supported_by" do
    context "returns" do
      it "Child_support supported by the admin in parameter" do
        expect(ChildSupport.supported_by(admin_user)).to match_array [first_child_support]
      end
    end
  end

  describe "#without_supporter" do
    context "returns" do
      it "Child_support without supporter" do
        expect(ChildSupport.without_supporter).to match_array [third_child_support, second_child_support]
      end
    end
  end

  (0..3).each do |call_idx|
    describe "call#{call_idx}_parent_progress_present" do
      context "returns" do
        it "child supports with parent progress in call #{call_idx} when the parameter is true" do
          first_child_support.update_columns("call#{call_idx}_parent_progress": ChildSupport::PARENT_PROGRESS.sample)

          expect(ChildSupport.method(:"call#{call_idx}_parent_progress_present").call(true)).to match_array [first_child_support]
        end
      end
    end

    describe "call#{call_idx}_sendings_benefits_present" do
      context "returns" do
        it "child supports with sendings benefits in call #{call_idx} when the parameter is true" do
          first_child_support.update_columns("call#{call_idx}_sendings_benefits": ChildSupport::SENDINGS_BENEFITS.sample)

          expect(ChildSupport.method(:"call#{call_idx}_sendings_benefits_present").call(true)).to match_array [first_child_support]
        end
      end
    end
  end

  describe "#groups_in(*v)" do
    context "returns" do
      it "child supports for child with group in v" do
        expect(ChildSupport.groups_in(group)).to match_array [first_child_support, second_child_support, third_child_support]
      end
    end
  end

  describe "#group_id_in(*v)" do
    context "returns" do
      it "child supports for child with group id in v" do
        expect(ChildSupport.group_id_in(group.id)).to match_array [first_child_support, second_child_support, third_child_support]
      end
    end
  end

  describe "#active_group_id_in(*v)" do
    context "returns" do
      it "child supports for unpaused child with group id in v" do
        expect(ChildSupport.active_group_id_in(group.id)).to match_array [first_child_support, second_child_support]
      end
    end
  end

  describe "#postal_code_contains(v)" do
    context "returns" do
      it "child supports for child with parent postal code contains v" do
        expect(ChildSupport.postal_code_contains(500)).to match_array [first_child_support, third_child_support]
      end
    end
  end

  describe "#postal_code_ends_with(v)" do
    context "returns" do
      it "child supports for child with parent postal code ends with v" do
        expect(ChildSupport.postal_code_ends_with(99)).to match_array [second_child_support]
      end
    end
  end

  describe "#postal_code_equals(v)" do
    context "returns" do
      it "child supports for child with parent postal code equals v" do
        expect(ChildSupport.postal_code_equals(75006)).to match_array [first_child_support, third_child_support]
      end
    end
  end

  describe "#postal_code_starts_with(v)" do
    context "returns" do
      it "child supports for child with parent postal code starts with v" do
        expect(ChildSupport.postal_code_starts_with(75)).to match_array [first_child_support, third_child_support]
      end
    end
  end

  describe "#copy_fields" do
    it "logs call_recording_consent value in notes" do
      source = FactoryBot.create(:child_support, current_child: first_child, call_recording_consent: '0_yes')
      target = FactoryBot.build(:child_support)
      target.copy_fields(source)
      expect(target.notes).to include('0_yes')
    end
  end

  describe '#stopped_for_unassigned_number?' do
    let(:child_support) { FactoryBot.create(:child_support) }

    it "est faux quand le timestamp est absent" do
      expect(child_support.stopped_for_unassigned_number?).to be false
    end

    it "est vrai quand le timestamp est présent" do
      child_support.update!(support_stopped_for_unassigned_number_at: Time.zone.now)
      expect(child_support.stopped_for_unassigned_number?).to be true
    end
  end

  describe 'effacement du marqueur de réactivation pour numéro erroné' do
    let(:child_support) do
      FactoryBot.create(:child_support, unassigned_number_reactivated_at: Time.zone.now)
    end

    it "efface le marqueur quand un statut d'appel change" do
      child_support.update!(call1_status: 'Numéro erroné')
      expect(child_support.reload.unassigned_number_reactivated_at).to be_nil
    end

    it "conserve le marqueur quand aucun statut d'appel ne change" do
      child_support.update!(important_information: 'note quelconque')
      expect(child_support.reload.unassigned_number_reactivated_at).to be_present
    end
  end

  describe '#pending_book_resend_date' do
    let_it_be(:book) { FactoryBot.create(:book) }
    let!(:next_resend_date) { BookShipmentDate.create!(date: Date.current + 10.days).date }
    # La validation refuse une date passée à la création : on la recale ensuite.
    let!(:last_shipment_date) do
      BookShipmentDate.create!(date: Date.current + 1.day).tap { |shipment| shipment.update_column(:date, Date.current - 45.days) }.date
    end
    # Second enfant sur la même fiche : l'alerte doit être propre à chaque enfant.
    let!(:sibling) do
      FactoryBot.create(:child, parent1: first_parent, group: group, group_status: 'active')
                .tap { |child| child.update!(child_support: first_child_support) }
    end

    # `book_condition_changed_at` étant posé à Time.zone.now par le before_save dès que
    # la condition est présente, antidater un signalement impose update_columns.
    def report_book_problem(child, reported_at:, resent_on: nil)
      FactoryBot.create(:children_support_module, child: child, parent: first_parent, book: book, book_condition: 'not_received')
                .update_columns(book_condition_changed_at: reported_at, book_resent_on: resent_on)
    end

    it "retourne nil quand aucun livre n'est signalé non reçu / défectueux" do
      expect(first_child_support.pending_book_resend_date(first_child.id)).to be_nil
    end

    it 'retourne la prochaine date de renvoi quand un livre est signalé depuis le dernier envoi' do
      report_book_problem(first_child, reported_at: 2.days.ago)

      expect(first_child_support.pending_book_resend_date(first_child.id)).to eq(next_resend_date)
    end

    it 'retourne nil quand le signalement est antérieur au dernier envoi' do
      report_book_problem(first_child, reported_at: last_shipment_date - 1.day)

      expect(first_child_support.pending_book_resend_date(first_child.id)).to be_nil
    end

    it 'retourne nil quand le livre signalé a déjà été renvoyé depuis le dernier envoi' do
      report_book_problem(first_child, reported_at: 2.days.ago, resent_on: Date.current - 1.day)

      expect(first_child_support.pending_book_resend_date(first_child.id)).to be_nil
    end

    it "retourne la prochaine date de renvoi quand un livre renvoyé lors d'un cycle précédent est re-signalé" do
      report_book_problem(first_child, reported_at: 2.days.ago, resent_on: last_shipment_date - 1.day)

      expect(first_child_support.pending_book_resend_date(first_child.id)).to eq(next_resend_date)
    end

    it "retourne nil pour un enfant de la fiche qui n'a pas de livre signalé" do
      report_book_problem(first_child, reported_at: 2.days.ago)

      expect(first_child_support.pending_book_resend_date(sibling.id)).to be_nil
    end

    it "retourne nil quand aucune date d'envoi n'est programmée" do
      report_book_problem(first_child, reported_at: 2.days.ago)
      BookShipmentDate.upcoming.destroy_all

      expect(first_child_support.pending_book_resend_date(first_child.id)).to be_nil
    end

    it "retourne nil quand l'adresse est suspectée invalide" do
      report_book_problem(first_child, reported_at: 2.days.ago)
      first_child_support.update!(address_suspected_invalid_at: Time.zone.now)

      expect(first_child_support.pending_book_resend_date(first_child.id)).to be_nil
    end
  end

  describe "#sensitive_information" do
    let(:texte) { "Père sous mesure d'éloignement" }
    let(:child_support) { FactoryBot.create(:child_support, supporter: admin_user) }

    context "quand un texte est enregistré" do
      before { child_support.update!(sensitive_information: texte) }

      it "le relit en clair via le modèle" do
        expect(ChildSupport.find(child_support.id).sensitive_information).to eq(texte)
      end

      it "ne stocke pas le texte en clair dans la colonne" do
        valeur_brute = ChildSupport.find(child_support.id).read_attribute_before_type_cast(:sensitive_information)

        expect(valeur_brute).to be_present
        expect(valeur_brute).not_to include("éloignement")
      end
    end

    context "quand le champ et un autre attribut sont modifiés" do
      before do
        child_support.update!(notes: "Appel du matin")
        child_support.update!(sensitive_information: texte, notes: "Appel du soir")
      end

      it "enregistre bien des versions pour l'autre attribut" do
        expect(child_support.versions.count).to be >= 2
      end

      it "n'écrit jamais le texte dans l'historique" do
        historique = child_support.versions.map { |version| [version.object, version.object_changes] }.to_json

        expect(historique).not_to include("éloignement")
        expect(historique).not_to include("sensitive_information")
      end
    end

    context "quand le texte ne contient que des espaces" do
      it "le considère comme vide" do
        child_support.update!(sensitive_information: "   ")

        expect(child_support.reload.sensitive_information).to be_nil
      end
    end

    context "quand le texte est une chaîne vide" do
      it "le considère comme vide" do
        child_support.update!(sensitive_information: "")

        expect(child_support.reload.sensitive_information).to be_nil
      end
    end

    context "quand le texte est vidé après avoir été renseigné" do
      it "repasse à nil" do
        child_support.update!(sensitive_information: texte)
        child_support.update!(sensitive_information: nil)

        expect(child_support.reload.sensitive_information).to be_nil
      end
    end

    context "quand la valeur a été chiffrée avec une autre clé" do
      before do
        autre_clef = ActiveRecord::Encryption::DerivedSecretKeyProvider.new("une autre clé")
        ActiveRecord::Encryption.with_encryption_context(key_provider: autre_clef) do
          child_support.update!(sensitive_information: texte)
        end
      end

      it "lève une erreur de déchiffrement à la lecture du champ" do
        expect { ChildSupport.find(child_support.id).sensitive_information }
          .to raise_error(ActiveRecord::Encryption::Errors::Decryption)
      end

      it "permet de lire les autres champs de la fiche" do
        expect(ChildSupport.find(child_support.id).supporter_id).to eq(admin_user.id)
      end
    end
  end

  describe "#ok_for_solicitation" do
    let(:child_support) { FactoryBot.create(:child_support, supporter: admin_user) }

    it "est vide par défaut" do
      expect(child_support.ok_for_solicitation).to be_nil
    end

    context "quand le texte sensible est vidé après avoir été renseigné" do
      it "repasse à vide" do
        child_support.update!(sensitive_information: "Père placé en foyer", ok_for_solicitation: false)
        child_support.update!(sensitive_information: "")

        expect(child_support.reload.ok_for_solicitation).to be_nil
      end
    end

    context "quand le texte sensible est modifié sans être vidé" do
      it "garde sa valeur" do
        child_support.update!(sensitive_information: "Père placé en foyer", ok_for_solicitation: false)
        child_support.update!(sensitive_information: "Mère hospitalisée")

        expect(child_support.reload.ok_for_solicitation).to be(false)
      end
    end

    context "quand il n'y a pas de texte sensible" do
      it "garde sa valeur lors d'un enregistrement avec un texte vide" do
        child_support.update!(ok_for_solicitation: true)
        child_support.update!(sensitive_information: "", notes: "Appel du soir")

        expect(child_support.reload.ok_for_solicitation).to be(true)
      end
    end

    context "quand le texte sensible est présent et le menu vide" do
      it "est valide" do
        child_support.sensitive_information = "Père placé en foyer"

        expect(child_support).to be_valid
      end
    end
  end

  describe "#sensitive_information_present?" do
    let(:child_support) { FactoryBot.create(:child_support, supporter: admin_user) }

    it "est faux sans texte" do
      expect(child_support.sensitive_information_present?).to be(false)
    end

    it "est vrai avec un texte" do
      child_support.update!(sensitive_information: "Père placé en foyer")

      expect(ChildSupport.find(child_support.id).sensitive_information_present?).to be(true)
    end

    it "est faux après le vidage du texte" do
      child_support.update!(sensitive_information: "Père placé en foyer")
      child_support.update!(sensitive_information: nil)

      expect(ChildSupport.find(child_support.id).sensitive_information_present?).to be(false)
    end

    it "est vrai même si le texte ne peut plus être déchiffré" do
      autre_clef = ActiveRecord::Encryption::DerivedSecretKeyProvider.new("une autre clé")
      fiche = ActiveRecord::Encryption.with_encryption_context(key_provider: autre_clef) do
        FactoryBot.create(:child_support, sensitive_information: "Père placé en foyer")
      end

      expect(ChildSupport.find(fiche.id).sensitive_information_present?).to be(true)
    end
  end

  describe ".ok_for_solicitation_is" do
    let!(:fiche_oui) { FactoryBot.create(:child_support, ok_for_solicitation: true) }
    let!(:fiche_non) { FactoryBot.create(:child_support, ok_for_solicitation: false) }
    let!(:fiche_vide) { FactoryBot.create(:child_support, ok_for_solicitation: nil) }

    it "retourne les fiches à Oui" do
      expect(ChildSupport.ok_for_solicitation_is("yes")).to contain_exactly(fiche_oui)
    end

    it "retourne les fiches à Non" do
      expect(ChildSupport.ok_for_solicitation_is("no")).to contain_exactly(fiche_non)
    end

    it "retourne les fiches vides" do
      resultat = ChildSupport.ok_for_solicitation_is("empty")

      expect(resultat).to include(fiche_vide)
      expect(resultat).not_to include(fiche_oui, fiche_non)
    end

    it "ne retourne aucune fiche pour une valeur inconnue" do
      expect(ChildSupport.ok_for_solicitation_is("peut-être")).to be_empty
    end
  end

  describe "#solicitation_alert?" do
    let(:child_support) { FactoryBot.create(:child_support, supporter: admin_user) }

    it "est vrai quand un texte sensible existe et que le menu est vide" do
      child_support.update!(sensitive_information: "Père placé en foyer")

      expect(child_support.solicitation_alert?).to be(true)
    end

    [true, false].each do |valeur|
      it "est faux quand un texte sensible existe et que le menu vaut #{valeur ? 'Oui' : 'Non'}" do
        child_support.update!(sensitive_information: "Père placé en foyer", ok_for_solicitation: valeur)

        expect(child_support.solicitation_alert?).to be(false)
      end
    end

    it "est faux sans texte sensible, même si le menu est vide" do
      expect(child_support.solicitation_alert?).to be(false)
    end

    it "est vrai même si le texte ne peut plus être déchiffré" do
      autre_clef = ActiveRecord::Encryption::DerivedSecretKeyProvider.new("une autre clé")
      fiche = ActiveRecord::Encryption.with_encryption_context(key_provider: autre_clef) do
        FactoryBot.create(:child_support, sensitive_information: "Père placé en foyer")
      end

      expect(ChildSupport.find(fiche.id).solicitation_alert?).to be(true)
    end
  end

  describe "#inspect" do
    it "ne montre pas le texte sensible" do
      fiche = FactoryBot.build(:child_support, sensitive_information: "Père placé en foyer")

      expect(fiche.inspect).not_to include("Père placé en foyer")
      expect(fiche.inspect).to include("sensitive_information: [FILTERED]")
    end
  end
end
