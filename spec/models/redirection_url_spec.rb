# == Schema Information
#
# Table name: redirection_urls
#
#  id                           :bigint           not null, primary key
#  discarded_at                 :datetime
#  redirection_url_visits_count :integer
#  security_code                :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  child_id                     :bigint
#  parent_id                    :bigint
#  redirection_target_id        :bigint
#
# Indexes
#
#  index_redirection_urls_on_child_id               (child_id)
#  index_redirection_urls_on_discarded_at           (discarded_at)
#  index_redirection_urls_on_parent_id              (parent_id)
#  index_redirection_urls_on_redirection_target_id  (redirection_target_id)
#

require "rails_helper"

RSpec.describe RedirectionUrl, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:redirection_url)).to be_valid
      end
    end

    context "fail" do
      it "if the url doesn't have security code" do
        expect(FactoryBot.build_stubbed(:redirection_url, security_code: nil)).not_to be_valid
      end
    end
  end

  describe "with_visits" do
    context "returns" do
      it "redirection urls visited" do
        first_url = FactoryBot.create(:redirection_url, redirection_url_visits: [FactoryBot.create(:redirection_url_visit)] )
        second_url = FactoryBot.create(:redirection_url, redirection_url_visits: [] )
        expect(RedirectionUrl.with_visits).to match_array [first_url]
        expect(RedirectionUrl.with_visits).not_to include second_url
      end
    end
  end
end
