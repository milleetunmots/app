# == Schema Information
#
# Table name: children
#
#  id                                         :bigint           not null, primary key
#  birthdate                                  :date             not null
#  discarded_at                               :datetime
#  family_redirection_unique_visit_rate       :float
#  family_redirection_url_unique_visits_count :integer
#  family_redirection_url_visits_count        :integer
#  family_redirection_urls_count              :integer
#  family_redirection_visit_rate              :float
#  first_name                                 :string           not null
#  gender                                     :string
#  has_quit_group                             :boolean          default(FALSE), not null
#  last_name                                  :string           not null
#  registration_source                        :string
#  registration_source_details                :string
#  security_code                              :string
#  should_contact_parent1                     :boolean          default(FALSE), not null
#  should_contact_parent2                     :boolean          default(FALSE), not null
#  src_url                                    :string
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  child_support_id                           :bigint
#  group_id                                   :bigint
#  parent1_id                                 :bigint           not null
#  parent2_id                                 :bigint
#
# Indexes
#
#  index_children_on_birthdate         (birthdate)
#  index_children_on_child_support_id  (child_support_id)
#  index_children_on_discarded_at      (discarded_at)
#  index_children_on_gender            (gender)
#  index_children_on_group_id          (group_id)
#  index_children_on_parent1_id        (parent1_id)
#  index_children_on_parent2_id        (parent2_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent1_id => parents.id)
#  fk_rails_...  (parent2_id => parents.id)
#

require 'rails_helper'

RSpec.describe Child, type: :model do

  before(:each) do
    @child = FactoryBot.build(:child)
  end

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        puts @child.inspect
        expect(FactoryBot.build_stubbed(:child)).to be_valid
      end
    end

=begin
    context "fail" do
      it "if the child doesn't have gender" do
        expect(FactoryBot.build_stubbed(:child, gender: nil)).to be_invalid
      end
      it "if the child's gender isn't male or female" do
        expect(FactoryBot.build_stubbed(:child, gender: nil)).to be_valid
      end
      it "if the child doesn't have first name" do

      end
      it "if the child doesn't have last name" do

      end
      it "if the child doesn't have birthdate" do

      end
      it "if the child doesn't have registration source" do

      end
      it "if the child doesn't have registration source detail" do

      end
      it "if the child doesn't have security code" do

      end

    end

=end
  end
end
