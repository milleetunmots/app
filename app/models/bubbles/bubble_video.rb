# == Schema Information
#
# Table name: bubble_videos
#
#  id              :bigint           not null, primary key
#  avis_nouveaute  :string
#  avis_pas_adapte :string
#  avis_rappel     :string
#  created_date    :date             not null
#  dislike         :integer
#  lien            :string
#  like            :integer
#  video           :string
#  video_type      :string
#  views           :integer
#
module Bubbles
  class BubbleVideo < ApplicationRecord
  end
end
