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
#  rcs_title1    :string(200)
#  rcs_title2    :string(200)
#  rcs_title3    :string(200)
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
#  rcs_media1_id :integer
#  rcs_media2_id :integer
#  rcs_media3_id :integer
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

  after_save :sync_rcs_models

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
      rcs_title1: rcs_title1,
      rcs_title2: rcs_title2,
      rcs_title3: rcs_title3,
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

  private

  def update_rcs_model1
    service = SpotHit::UpdateRcsModelService.new(text_messages_bundle: self, message_index: 1).call
    Rollbar.error('SpotHit::UpdateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
  end

  def update_rcs_model2
    service = SpotHit::UpdateRcsModelService.new(text_messages_bundle: self, message_index: 2).call
    Rollbar.error('SpotHit::UpdateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
  end

  def sync_rcs_models
    (1..3).each do |index|
      next if send("body#{index}").blank?

      if send("rcs_media#{index}_id").present? && send("image#{index}_id").nil?
        SpotHit::DeleteRcsModelJob.set(wait_until: 2.months.from_now).perform_later(send("rcs_media#{index}_id"))
        update_column("rcs_media#{index}_id", nil)
      elsif send("rcs_media#{index}_id").present? && (send("saved_change_to_body#{index}?") || send("saved_change_to_image#{index}_id?") || send("saved_change_to_rcs_title#{index}?"))
        service = SpotHit::UpdateRcsModelService.new(text_messages_bundle: self, message_index: index).call
        Rollbar.error('SpotHit::UpdateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
      elsif send("rcs_media#{index}_id").nil? && send("image#{index}_id").present?
        service = SpotHit::CreateRcsModelService.new(text_messages_bundle: self, message_index: index).call
        Rollbar.error('SpotHit::CreateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
      end
    end
  end
end
