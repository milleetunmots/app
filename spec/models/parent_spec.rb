# == Schema Information
#
# Table name: parents
#
#  id                                  :bigint           not null, primary key
#  address                             :string           not null
#  city_name                           :string           not null
#  degree                              :string
#  degree_in_france                    :boolean
#  discarded_at                        :datetime
#  email                               :string
#  family_followed                     :boolean          default(FALSE)
#  first_name                          :string           not null
#  follow_us_on_facebook               :boolean
#  follow_us_on_whatsapp               :boolean
#  gender                              :string           not null
#  help_my_child_to_learn_is_important :string
#  is_ambassador                       :boolean
#  is_excluded_from_workshop           :boolean          default(FALSE)
#  job                                 :string
#  last_name                           :string           not null
#  letterbox_name                      :string
#  mid_term_rate                       :integer
#  mid_term_reaction                   :string
#  mid_term_speech                     :text
#  phone_number                        :string           not null
#  phone_number_national               :string
#  postal_code                         :string           not null
#  present_on_facebook                 :boolean
#  present_on_whatsapp                 :boolean
#  redirection_unique_visit_rate       :float
#  redirection_url_unique_visits_count :integer
#  redirection_url_visits_count        :integer
#  redirection_urls_count              :integer
#  redirection_visit_rate              :float
#  security_code                       :string
#  terms_accepted_at                   :datetime
#  would_like_to_do_more               :string
#  would_receive_advices               :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#
# Indexes
#
#  index_parents_on_address                (address)
#  index_parents_on_city_name              (city_name)
#  index_parents_on_discarded_at           (discarded_at)
#  index_parents_on_email                  (email)
#  index_parents_on_first_name             (first_name)
#  index_parents_on_gender                 (gender)
#  index_parents_on_is_ambassador          (is_ambassador)
#  index_parents_on_job                    (job)
#  index_parents_on_last_name              (last_name)
#  index_parents_on_phone_number_national  (phone_number_national)
#  index_parents_on_postal_code            (postal_code)
#

require "rails_helper"

RSpec.describe Parent, type: :model do
  subject { FactoryBot.create(:parent, email: Faker::Internet.email) }

  describe "#gender" do
    it "is required" do
      subject.gender = nil

      expect(subject).to_not be_valid
    end

    it "is included in GENDERS" do
      subject.gender = "x"

      expect(subject).to_not be_valid
    end
  end

  describe "#first_name" do
    it "is required" do
      subject.first_name = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#last_name" do
    it "is required" do
      subject.last_name = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#letterbox_name" do
    it "is required" do
      subject.letterbox_name = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#address" do
    it "is required" do
      subject.address = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#city_name" do
    it "is required" do
      subject.city_name = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#postal_code" do
    it "is required" do
      subject.postal_code = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#phone_number" do
    it "is required" do
      subject.phone_number = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#email" do
    let(:another_parent) { FactoryBot.build(:parent, email: subject.email) }

    it "is unique" do
      expect(another_parent).to_not be_valid
    end
  end

  describe "#terms_accepted_at" do
    it "is required" do
      subject.terms_accepted_at = nil

      expect(subject).to_not be_valid
    end
  end

  describe "#update_counters!" do
    context "if the parent doesn't have redirections urls, set" do
      it "redirection_url_unique_visits_count to 0" do
        subject.update_counters!

        expect(subject.redirection_url_unique_visits_count).to eq 0
      end

      it "redirection_unique_visit_rate to 0" do
        subject.update_counters!

        expect(subject.redirection_unique_visit_rate).to eq 0
      end

      it "redirection_url_visits_count to 0" do
        subject.update_counters!

        expect(subject.redirection_url_visits_count).to eq 0
      end

      it "redirection_visit_rate to 0" do
        subject.update_counters!

        expect(subject.redirection_visit_rate).to eq 0
      end
    end

    # context "if the parent have redirections urls, set" do
    #   let(:first_child) { FactoryBot.create(:child, parent1: subject) }
    #   let(:second_child) { FactoryBot.create(:child, parent1: subject) }
    #   let(:first_redirection_url) { FactoryBot.create(:redirection_url, child: first_child, parent: subject) }
    #   let(:second_redirection_url) { FactoryBot.create(:redirection_url, child: second_child, parent: subject) }
    #
    #   it "redirection_url_unique_visits_count to number of urls the parents visited" do
    #     first_redirection_url.update! redirection_url_visits_count: 2
    #     second_redirection_url.update! redirection_url_visits_count: 1
    #     subject.update_counters!
    #
    #     expect(subject.redirection_url_unique_visits_count).to eq 2
    #   end
    #
    #   it "redirection_url_visits_count to sum of redirection_url_visits_count" do
    #     first_redirection_url.update! redirection_url_visits_count: 2
    #     second_redirection_url.update! redirection_url_visits_count: 5
    #     subject.update_counters!
    #
    #     expect(subject.redirection_url_visits_count).to eq 7
    #   end
    #
    #   it "redirection_unique_visit_rate to ratio redirection_url_unique_visits_count / redirection_urls_count" do
    #     first_redirection_url.update! redirection_url_visits_count: 2
    #     second_redirection_url.update! redirection_url_visits_count: 0
    #     subject.update_counters!
    #
    #     expect(subject.redirection_unique_visit_rate).to eq 0.5
    #   end
    #
    #   it "redirection_visit_rate to ratio redirection_url_visits_count / redirection_urls_count" do
    #     first_redirection_url.update! redirection_url_visits_count: 2
    #     second_redirection_url.update! redirection_url_visits_count: 3
    #     subject.update_counters!
    #
    #     expect(subject.redirection_visit_rate).to eq 5 / 2.to_f
    #   end
    # end
  end

  describe "#duplicate_of?(another_parent)" do
    let(:another_parent) { FactoryBot.build(:parent, first_name: subject.first_name, last_name: subject.last_name, phone_number: subject.phone_number) }

    context "returns true if another_parent is a double of the current parent" do
      it { expect(subject.duplicate_of?(another_parent)).to be_truthy }
    end
  end
end
