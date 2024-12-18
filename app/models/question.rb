# == Schema Information
#
# Table name: questions
#
#  id                       :bigint           not null, primary key
#  body                     :text             not null
#  with_open_ended_response :boolean          default(TRUE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  survey_id                :bigint           not null
#
# Indexes
#
#  index_questions_on_survey_id  (survey_id)
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

  validates :body, presence: true

end
