# == Schema Information
#
# Table name: questions
#
#  id                       :bigint           not null, primary key
#  name                     :text             not null
#  order                    :integer          not null
#  uid                      :text             not null
#  with_open_ended_response :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  survey_id                :bigint           not null
#
# Indexes
#
#  index_questions_on_survey_id  (survey_id)
#  index_questions_on_uid        (uid) UNIQUE
#
class Question < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :survey
  has_many :answers, dependent: :destroy

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true
  validates :order, presence: true
  validates :uid, presence: true, uniqueness: { case_sensitive: false }
end
