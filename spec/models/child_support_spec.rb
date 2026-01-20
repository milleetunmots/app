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
#  child_count                                :integer
#  discarded_at                               :datetime
#  family_support_should_be_stopped           :string
#  has_important_information_parental_consent :boolean          default(FALSE), not null
#  important_information                      :text
#  instagram_follower                         :string
#  instagram_user                             :string
#  is_bilingual                               :string           default("2_no_information")
#  most_present_parent                        :string
#  notes                                      :text
#  other_phone_number                         :string
#  parent1_available_support_module_list      :string           is an Array
#  parent2_available_support_module_list      :string           is an Array
#  parent_mid_term_rate                       :integer
#  parent_mid_term_reaction                   :string
#  parental_contexts                          :string           is an Array
#  restart_support_date                       :datetime
#  restart_support_details                    :text
#  second_language                            :string
#  should_be_read                             :boolean
#  stop_support_date                          :datetime
#  stop_support_details                       :text
#  stop_support_reason                        :string
#  suggested_videos_counter                   :jsonb            is an Array
#  to_call                                    :boolean
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
#  index_child_supports_on_should_be_read                         (should_be_read)
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
end
