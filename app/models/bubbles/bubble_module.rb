# == Schema Information
#
# Table name: bubble_modules
#
#  id                  :bigint           not null, primary key
#  age                 :string           is an Array
#  created_date        :date             not null
#  description         :text
#  niveau              :string
#  theme               :string
#  titre               :string
#  module_precedent_id :bigint
#  module_suivant_id   :bigint
#  video_princ_id      :bigint
#  video_tem_id        :bigint
#
# Indexes
#
#  index_bubble_modules_on_age                  (age) USING gin
#  index_bubble_modules_on_module_precedent_id  (module_precedent_id)
#  index_bubble_modules_on_module_suivant_id    (module_suivant_id)
#  index_bubble_modules_on_video_princ_id       (video_princ_id)
#  index_bubble_modules_on_video_tem_id         (video_tem_id)
#
# Foreign Keys
#
#  fk_rails_...  (module_precedent_id => bubble_modules.id)
#  fk_rails_...  (module_suivant_id => bubble_modules.id)
#  fk_rails_...  (video_princ_id => bubble_videos.id)
#  fk_rails_...  (video_tem_id => bubble_videos.id)
#
module Bubbles
  class BubbleModule < ApplicationRecord
    belongs_to :module_precedent, class_name: 'Bubbles::BubbleModule', optional: true
    belongs_to :module_suivant, class_name: 'Bubbles::BubbleModule', optional: true
    belongs_to :video_princ, class_name: 'Bubbles::BubbleVideo', optional: true
    belongs_to :video_tem, class_name: 'Bubbles::BubbleVideo', optional: true
  end
end
