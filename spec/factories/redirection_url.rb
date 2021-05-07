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

FactoryBot.define do
  factory :redirection_url do
    association :redirection_target, factory: :redirection_target
    association :child, factory: :child

    parent { child.parent1 }
  end
end
