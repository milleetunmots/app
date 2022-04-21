# == Schema Information
#
# Table name: redirection_targets
#
#  id                                         :bigint           not null, primary key
#  discarded_at                               :datetime
#  family_redirection_url_unique_visits_count :integer
#  family_redirection_url_visits_count        :integer
#  family_redirection_urls_count              :integer
#  family_unique_visit_rate                   :float
#  family_visit_rate                          :float
#  redirection_urls_count                     :integer
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  medium_id                                  :bigint
#
# Indexes
#
#  index_redirection_targets_on_discarded_at  (discarded_at)
#  index_redirection_targets_on_medium_id     (medium_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (medium_id => media.id)
#

require "rails_helper"

RSpec.describe RedirectionTarget, type: :model do
  # before(:each) do
  #   @redirection_uls_without_visit = FactoryBot.build(:redirection_url)
  #   @redirection_uls_with_visit = FactoryBot.build(:redirection_url, redirection_url_visits: [FactoryBot.build(:redirection_url_visit)])
  #   @redirection_target_without_urls = FactoryBot.build(:redirection_target)
  #   @redirection_target_with_urls = FactoryBot.build(:redirection_target, redirection_urls: [@redirection_uls_without_visit, @redirection_uls_with_visit])
  # end
  #
  # describe ".update_counters!" do
  #   context "if family_redirection_urls_count is zero, set" do
  #     it "family_redirection_url_unique_visits_count to 0" do
  #       @redirection_target_without_urls.update_counters!
  #       expect(@redirection_target_without_urls.family_redirection_url_unique_visits_count).to eq 0
  #     end
  #
  #     it "family_unique_visit_rate to 0" do
  #       @redirection_target_without_urls.update_counters!
  #       expect(@redirection_target_without_urls.family_unique_visit_rate).to eq 0
  #     end
  #
  #     it "family_redirection_url_visits_count to 0" do
  #       @redirection_target_without_urls.update_counters!
  #       expect(@redirection_target_without_urls.family_redirection_url_visits_count).to eq 0
  #     end
  #
  #     it "family_visit_rate to 0" do
  #       @redirection_target_without_urls.update_counters!
  #       expect(@redirection_target_without_urls.family_visit_rate).to eq 0
  #     end
  #   end
  #
  #   context "if family_redirection_urls_count isn't zero, set" do
  #     it "family_redirection_url_unique_visits_count to number of redirection urls visited" do
  #       @redirection_target_with_urls.update_counters!
  #       expect(@redirection_target_with_urls.family_redirection_url_unique_visits_count).to eq 1
  #     end
  #
  #     it "family_redirection_url_visits_count to sum of redirection_url_visits_count" do
  #       @redirection_target_with_urls.update_counters!
  #       expect(@redirection_target_with_urls.family_redirection_url_visits_count).to eq 1
  #     end
  #
  #     it "family_unique_visit_rate to family_redirection_url_unique_visits_count / family_redirection_urls_count" do
  #       @redirection_target_with_urls.update_counters!
  #       expect(@redirection_target_with_urls.family_unique_visit_rate).to eq 0.5
  #     end
  #
  #     it "family_visit_rate to family_redirection_url_visits_count / family_redirection_urls_count" do
  #       @redirection_target_with_urls.update_counters!
  #       expect(@redirection_target_with_urls.family_visit_rate).to eq 0.5
  #     end
  #   end
  # end
end
