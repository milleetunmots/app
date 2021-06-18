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

FactoryBot.define do
  factory :field_comment do
    association :author, factory: :admin_user
    association :related, factory: :parent

    field { related.attributes.keys.sample }
  end
end
