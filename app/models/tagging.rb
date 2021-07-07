class Tagging < ApplicationRecord

  scope :by_taggable_type, -> (type) { where(taggable_type: type) }
  scope :by_tag_id, -> (tag_id) { where(tag_id: tag_id) }

end