# == Schema Information
#
# Table name: children_sources
#
#  id                      :bigint           not null, primary key
#  detail                  :text
#  registration_department :integer
#  child_id                :bigint
#  source_id               :bigint
#
# Indexes
#
#  index_children_sources_on_child_id   (child_id)
#  index_children_sources_on_source_id  (source_id)
#
class ChildrenSource < ApplicationRecord
  belongs_to :source
  belongs_to :child
end
