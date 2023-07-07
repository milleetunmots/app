# == Schema Information
#
# Table name: bubble_modules
#
#  id           :bigint           not null, primary key
#  created_date :date             not null
#  description  :text
#  niveau       :integer
#
module Bubble
  class BubbleModule < ApplicationRecord
    belongs_to :module_precedent, class_name: 'Bubble::BubbleModule', optional: true
    belongs_to :moduel_suivant, class_name: 'Bubble::BubbleModule', optional: true
  end
end
