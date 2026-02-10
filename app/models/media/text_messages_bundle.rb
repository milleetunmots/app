# == Schema Information
#
# Table name: media
#
#  id           :bigint           not null, primary key
#  body1        :text
#  body2        :text
#  body3        :text
#  discarded_at :datetime
#  name         :string
#  theme        :string
#  type         :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  airtable_id  :string
#  folder_id    :bigint
#  image1_id    :bigint
#  image2_id    :bigint
#  image3_id    :bigint
#  link1_id     :bigint
#  link2_id     :bigint
#  link3_id     :bigint
#  spot_hit_id  :string
#
# Indexes
#
#  index_media_on_airtable_id   (airtable_id) UNIQUE
#  index_media_on_discarded_at  (discarded_at)
#  index_media_on_folder_id     (folder_id)
#  index_media_on_image1_id     (image1_id)
#  index_media_on_image2_id     (image2_id)
#  index_media_on_image3_id     (image3_id)
#  index_media_on_link1_id      (link1_id)
#  index_media_on_link2_id      (link2_id)
#  index_media_on_link3_id      (link3_id)
#  index_media_on_type          (type)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => media_folders.id)
#  fk_rails_...  (image1_id => media.id)
#  fk_rails_...  (image2_id => media.id)
#  fk_rails_...  (image3_id => media.id)
#  fk_rails_...  (link1_id => media.id)
#  fk_rails_...  (link2_id => media.id)
#  fk_rails_...  (link3_id => media.id)
#

class Media::TextMessagesBundle < Medium

  include Media::TextMessagesBundleConcern

  def draft
    update_attribute :type, 'Media::TextMessagesBundleDraft'
  end

  def self.single_message
    where.not(
      body1: [nil, '']
    ).where(
      body2: [nil, ''],
      body3: [nil, '']
    )
  end

  def duplicate
    self.class.new(
      name: "Copie de #{name}",
      tag_list: tag_list,
      folder_id: folder_id,
      type: type,
      body1: body1,
      body2: body2,
      body3: body3,
      link1_id: link1_id,
      link2_id: link2_id,
      link3_id: link3_id,
      image1_id: image1_id,
      image2_id: image2_id,
      image3_id: image3_id
    )
  end

end
