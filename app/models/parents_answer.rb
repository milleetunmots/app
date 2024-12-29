# == Schema Information
#
# Table name: parents_answers
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  answer_id  :bigint           not null
#  parent_id  :bigint           not null
#
# Indexes
#
#  index_parents_answers_on_answer_id  (answer_id)
#  index_parents_answers_on_parent_id  (parent_id)
#
class ParentsAnswer < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :parent
  belongs_to :answer

end
