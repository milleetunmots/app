# == Schema Information
#
# Table name: answers
#
#  id          :bigint           not null, primary key
#  options     :text             is an Array
#  response    :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  question_id :bigint           not null
#
# Indexes
#
#  index_answers_on_question_id  (question_id)
#
class Answer < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :question
  has_one :parents_answer, dependent: :destroy

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :response, presence: true

end
