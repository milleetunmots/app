# == Schema Information
#
# Table name: bubble_sessions
#
#  id                 :bigint           not null, primary key
#  avis_contenu       :string
#  avis_rappel        :integer
#  avis_video         :string
#  child_session      :string
#  created_date       :date
#  derniere_ouverture :datetime
#  import_date        :datetime
#  lien               :string
#  pourcentage_video  :integer
#  bubble_id          :string           not null
#  module_session_id  :bigint
#  video_id           :bigint
#
# Indexes
#
#  index_bubble_sessions_on_module_session_id  (module_session_id)
#  index_bubble_sessions_on_video_id           (video_id)
#
# Foreign Keys
#
#  fk_rails_...  (module_session_id => bubble_modules.id)
#  fk_rails_...  (video_id => bubble_videos.id)
#
module Bubbles
  class BubbleSession < ApplicationRecord
    belongs_to :module_session, class_name: 'Bubbles::BubbleModule', optional: true
    belongs_to :video, class_name: 'Bubbles::BubbleVideo', optional: true
  end
end
