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

FactoryBot.define do
  factory :redirection_url_visit do
    association :redirection_url, factory: :redirection_url

    occurred_at { Faker::Date.backward(days: 30) }
  end
end
