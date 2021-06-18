# == Schema Information
#
# Table name: redirection_url_visits
#
#  id                 :bigint           not null, primary key
#  occurred_at        :datetime
#  redirection_url_id :bigint
#
# Indexes
#
#  index_redirection_url_visits_on_redirection_url_id  (redirection_url_id)
#

require "rails_helper"

RSpec.describe RedirectionUrlVisit, type: :model do
  describe "Validations" do
    context "succeed" do
      it "the visit has been occurred" do
        expect(FactoryBot.build_stubbed(:redirection_url_visit)).to be_valid
      end
    end

    context "fail" do
      it "the visit hasn't been occurred" do
        expect(FactoryBot.build_stubbed(:redirection_url_visit, occurred_at: nil)).not_to be_valid
      end
    end
  end
end
