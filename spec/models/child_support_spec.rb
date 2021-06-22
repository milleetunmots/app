# == Schema Information
#
# Table name: child_supports
#
#  id                              :bigint           not null, primary key
#  book_not_received               :string
#  call1_books_quantity            :integer
#  call1_duration                  :integer
#  call1_goals                     :text
#  call1_language_awareness        :string
#  call1_language_development      :text
#  call1_notes                     :text
#  call1_parent_actions            :text
#  call1_parent_progress           :string
#  call1_reading_frequency         :string
#  call1_sendings_benefits         :string
#  call1_sendings_benefits_details :text
#  call1_status                    :string
#  call1_status_details            :text
#  call1_technical_information     :text
#  call2_duration                  :integer
#  call2_goals                     :text
#  call2_language_awareness        :string
#  call2_language_development      :text
#  call2_notes                     :text
#  call2_parent_actions            :text
#  call2_parent_progress           :string
#  call2_reading_frequency         :string
#  call2_sendings_benefits         :string
#  call2_sendings_benefits_details :text
#  call2_status                    :string
#  call2_status_details            :text
#  call2_technical_information     :text
#  call3_duration                  :integer
#  call3_goals                     :text
#  call3_language_awareness        :string
#  call3_language_development      :text
#  call3_notes                     :text
#  call3_parent_actions            :text
#  call3_parent_progress           :string
#  call3_reading_frequency         :string
#  call3_sendings_benefits         :string
#  call3_sendings_benefits_details :text
#  call3_status                    :string
#  call3_status_details            :text
#  call3_technical_information     :text
#  call4_duration                  :integer
#  call4_goals                     :text
#  call4_language_awareness        :string
#  call4_language_development      :text
#  call4_notes                     :text
#  call4_parent_actions            :text
#  call4_parent_progress           :string
#  call4_reading_frequency         :string
#  call4_sendings_benefits         :string
#  call4_sendings_benefits_details :text
#  call4_status                    :string
#  call4_status_details            :text
#  call4_technical_information     :text
#  call5_duration                  :integer
#  call5_goals                     :text
#  call5_language_awareness        :string
#  call5_language_development      :text
#  call5_notes                     :text
#  call5_parent_actions            :text
#  call5_parent_progress           :string
#  call5_reading_frequency         :string
#  call5_sendings_benefits         :string
#  call5_sendings_benefits_details :text
#  call5_status                    :string
#  call5_status_details            :text
#  call5_technical_information     :text
#  discarded_at                    :datetime
#  important_information           :text
#  is_bilingual                    :boolean
#  second_language                 :string
#  should_be_read                  :boolean
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  supporter_id                    :bigint
#
# Indexes
#
#  index_child_supports_on_book_not_received         (book_not_received)
#  index_child_supports_on_call1_parent_progress     (call1_parent_progress)
#  index_child_supports_on_call1_reading_frequency   (call1_reading_frequency)
#  index_child_supports_on_call2_language_awareness  (call2_language_awareness)
#  index_child_supports_on_call2_parent_progress     (call2_parent_progress)
#  index_child_supports_on_call3_language_awareness  (call3_language_awareness)
#  index_child_supports_on_call3_parent_progress     (call3_parent_progress)
#  index_child_supports_on_call4_language_awareness  (call4_language_awareness)
#  index_child_supports_on_call4_parent_progress     (call4_parent_progress)
#  index_child_supports_on_call5_language_awareness  (call5_language_awareness)
#  index_child_supports_on_call5_parent_progress     (call5_parent_progress)
#  index_child_supports_on_discarded_at              (discarded_at)
#  index_child_supports_on_should_be_read            (should_be_read)
#  index_child_supports_on_supporter_id              (supporter_id)
#
# Foreign Keys
#
#  fk_rails_...  (supporter_id => admin_users.id)

require "rails_helper"

RSpec.describe ChildSupport, type: :model do
  before(:each) do
    @first_parent = FactoryBot.create(:parent, postal_code: 75006)
    @second_parent = FactoryBot.create(:parent, postal_code: 99999)
    @group = FactoryBot.create(:group)
    @first_child = FactoryBot.create(:child, group: @group, registration_source: "pmi", parent1: @first_parent)
    @second_child = FactoryBot.create(:child, group: @group, has_quit_group: true, parent1: @first_parent, registration_source: "caf")
    @third_child = FactoryBot.create(:child, registration_source: "pmi", registration_source_details: "Aristide Bamenou", parent1: @second_parent)
    @admin_user = FactoryBot.create(:admin_user)
    @first_child_support = FactoryBot.create(:child_support, first_child: @first_child, supporter: @admin_user)
    @second_child_support = FactoryBot.create(:child_support)
    @third_child_support = FactoryBot.create(:child_support, first_child: @second_child)
    @fourth_child_support = FactoryBot.create(:child_support, first_child: @third_child)
  end

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:child_support)).to be_valid
      end

      (1..5).each do |call_idx|
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
        expect(ChildSupport.supported_by(@admin_user)).to match_array [@first_child_support]
      end
    end
  end

  describe "#without_supporter" do
    context "returns" do
      it "Child_support without supporter" do
        expect(ChildSupport.without_supporter).to match_array [@second_child_support, @third_child_support, @fourth_child_support]
      end
    end
  end

  (1..5).each do |call_idx|
    describe "call#{call_idx}_parent_progress_present" do
      context "returns" do
        it "child supports with parent progress in call #{call_idx} when the parameter is true" do
          first_child_support = FactoryBot.create(
            :child_support, "call#{call_idx}_parent_progress": ChildSupport::PARENT_PROGRESS.sample
          )
          second_child_support = FactoryBot.create(:child_support)
          expect(ChildSupport.method(:"call#{call_idx}_parent_progress_present").call(true)).to match_array [first_child_support]
        end
      end
    end

    describe "call#{call_idx}_sendings_benefits_present" do
      context "returns" do
        it "child supports with sendings benefits in call #{call_idx} when the parameter is true" do
          first_child_support = FactoryBot.create(
            :child_support, "call#{call_idx}_sendings_benefits": ChildSupport::SENDINGS_BENEFITS.sample
          )
          second_child_support = FactoryBot.create(:child_support)
          expect(ChildSupport.method(:"call#{call_idx}_sendings_benefits_present").call(true)).to match_array [first_child_support]
        end
      end
    end
  end

  describe "#groups_in(*v)" do
    context "returns" do
      it "child supports for child with group in v" do
        expect(ChildSupport.groups_in(@group.id)).to match_array [@first_child_support, @third_child_support]
      end
    end
  end

  describe "#group_id_in(*v)" do
    context "returns" do
      it "child supports for child with group id in v" do
        expect(ChildSupport.group_id_in(@group.id)).to match_array [@first_child_support, @third_child_support]
      end
    end
  end

  describe "#unpaused_group_id_in(*v)" do
    context "returns" do
      it "child supports for unpaused child with group id in v" do
        expect(ChildSupport.unpaused_group_id_in(@group.id)).to match_array [@first_child_support]
      end
    end
  end

  describe "#registration_sources_in(*v)" do
    context "returns" do
      it "child supports for child with registration sources in v" do
        expect(ChildSupport.registration_sources_in("pmi")).to match_array [@first_child_support, @fourth_child_support]
      end
    end
  end

  describe "#registration_sources_details_in(*v)" do
    context "returns" do
      it "child supports for child with registration sources details in v" do
        expect(ChildSupport.registration_sources_details_in("Aristide Bamenou")).to match_array [@fourth_child_support]
      end
    end
  end

  describe "#postal_code_contains(v)" do
    context "returns" do
      it "child supports for child with parent postal code contains v" do
        expect(ChildSupport.postal_code_contains(500)).to match_array [@first_child_support, @third_child_support]
      end
    end
  end

  describe "#postal_code_ends_with(v)" do
    context "returns" do
      it "child supports for child with parent postal code ends with v" do
        expect(ChildSupport.postal_code_ends_with(99)).to match_array [@fourth_child_support]
      end
    end
  end

  describe "#postal_code_equals(v)" do
    context "returns" do
      it "child supports for child with parent postal code equals v" do
        expect(ChildSupport.postal_code_equals(75006)).to match_array [@first_child_support, @third_child_support]
      end
    end
  end

  describe "#postal_code_starts_with(v)" do
    context "returns" do
      it "child supports for child with parent postal code starts with v" do
        expect(ChildSupport.postal_code_starts_with(75)).to match_array [@first_child_support, @third_child_support]
      end
    end
  end


end
