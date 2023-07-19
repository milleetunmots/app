# == Schema Information
#
# Table name: bubble_contents
#
#  id                :bigint           not null, primary key
#  age               :string           is an Array
#  avis_nouveaute    :integer
#  avis_pas_adapte   :integer
#  avis_rappel       :integer
#  content_type      :string
#  created_date      :date             not null
#  description       :text
#  titre             :string
#  bubble_id         :string           not null
#  module_content_id :bigint
#
# Indexes
#
#  index_bubble_contents_on_age                (age) USING gin
#  index_bubble_contents_on_module_content_id  (module_content_id)
#
# Foreign Keys
#
#  fk_rails_...  (module_content_id => bubble_modules.id)
#
module Bubbles
  class BubbleContent < ApplicationRecord
    belongs_to :module_content, class_name: 'Bubbles::BubbleModule', optional: true
  end
end
