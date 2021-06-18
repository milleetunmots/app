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

FactoryBot.define do
  factory :redirection_target do
    association :medium, factory: :medium
  end
end
