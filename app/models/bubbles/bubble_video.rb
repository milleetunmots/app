# == Schema Information
#
# Table name: bubble_videos
#
#  id              :bigint           not null, primary key
#  avis_nouveaute  :integer
#  avis_pas_adapte :integer
#  avis_rappel     :integer
#  created_date    :date             not null
#  dislike         :integer
#  lien            :string
#  like            :integer
#  video           :string
#  video_type      :string
#  views           :integer
#  bubble_id       :string           not null
#
module Bubbles
  class BubbleVideo < ApplicationRecord
    has_many :bubble_sessions, dependent: :nullify
    has_many :buble_modules_princs, class_name: 'Bubbles::BubbleModule', foreign_key: :video_princ_id, dependent: :nullify, inverse_of: :video_princ
    has_many :buble_modules_tems, class_name: 'Bubbles::BubbleModule', foreign_key: :video_tem_id, dependent: :nullify, inverse_of: :video_tem
  end
end
