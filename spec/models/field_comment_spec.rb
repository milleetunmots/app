# == Schema Information
#
# Table name: field_comments
#
#  id           :bigint           not null, primary key
#  content      :text
#  field        :string
#  related_type :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  author_id    :bigint
#  related_id   :bigint
#
# Indexes
#
#  index_field_comments_on_author_id                    (author_id)
#  index_field_comments_on_related_type_and_related_id  (related_type,related_id)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => admin_users.id)
#

require "rails_helper"

RSpec.describe FieldComment, type: :model do

  let_it_be(:first_admin, reload: true) { FactoryBot.create(:admin_user) }
  let_it_be(:second_admin, reload: true) { FactoryBot.create(:admin_user) }

  let_it_be(:first_parent, reload: true) { FactoryBot.create(:parent) }
  let_it_be(:second_parent, reload: true) { FactoryBot.create(:parent) }

  let_it_be(:first_field_comment, reload: true) { FactoryBot.create(:field_comment, author: first_admin, related: first_parent, field: "last_name") }
  let_it_be(:second_field_comment, reload: true) { FactoryBot.create(:field_comment, author: second_admin, related: second_parent) }

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:field_comment)).to be_valid
      end
    end

    context "fail" do
      it "if field aren't present" do
        expect(FactoryBot.build_stubbed(:field_comment, field: nil)).not_to be_valid
      end
    end
  end

  describe "#posted_by" do
    context "returns" do
      it "field comments posted by the admin_user in parameter" do
        expect(FieldComment.posted_by(first_admin)).to match_array [first_field_comment]
        expect(FieldComment.posted_by(second_admin)).to match_array [second_field_comment]
      end
    end
  end

  describe "#relating" do
    context "returns" do
      it "field comments relating the model in parameter" do
        expect(FieldComment.relating(first_parent)).to match_array [first_field_comment]
        expect(FieldComment.relating(second_parent)).to match_array [second_field_comment]
      end
    end
  end

  # describe "#concerning" do
  #   context "returns" do
  #     it "field comments concerning the field in parameter" do
  #       expect(FieldComment.concerning("last_name")).to match_array [first_field_comment]
  #     end
  #   end
  # end
end
