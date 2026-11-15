# == Schema Information
#
# Table name: media
#
#  id                 :bigint           not null, primary key
#  body1              :text
#  body2              :text
#  body3              :text
#  discarded_at       :datetime
#  name               :string
#  rcs_cta_title1     :string
#  rcs_cta_title2     :string
#  rcs_cta_title3     :string
#  rcs_text_template1 :boolean          default(FALSE), not null
#  rcs_text_template2 :boolean          default(FALSE), not null
#  rcs_text_template3 :boolean          default(FALSE), not null
#  rcs_title1         :string(200)
#  rcs_title2         :string(200)
#  rcs_title3         :string(200)
#  theme              :string
#  type               :string
#  url                :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  airtable_id        :string
#  folder_id          :bigint
#  image1_id          :bigint
#  image2_id          :bigint
#  image3_id          :bigint
#  link1_id           :bigint
#  link2_id           :bigint
#  link3_id           :bigint
#  rcs_media1_id      :integer
#  rcs_media2_id      :integer
#  rcs_media3_id      :integer
#  spot_hit_id        :string
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

  # SpotHit compte en octets UTF-8 (un accent = 2 octets, € = 3, etc.),
  # d'où le seuil exprimé en bytesize.
  MESSAGE_TYPE_MAX_BYTESIZE = 160

  after_save :sync_rcs_models

  def draft
    update_attribute :type, 'Media::TextMessagesBundleDraft'
  end

  # Type d'envoi SpotHit du message d'index donné (1..3) :
  # - 'single' : une image est présente (RCS avec média) ;
  # - 'basic'  : pas d'image et message envoyé ≤ 160 octets (RCS basic) ;
  # - 'single texte' ou 'sms' : texte long sans image, selon RCS_SINGLE_TEXT_ENABLED.
  def message_type(index)
    return 'single' if public_send("image#{index}_id").present?
    return 'basic' unless long_message?(index)

    self.class.rcs_single_text_enabled? ? 'single texte' : 'sms'
  end

  def self.rcs_single_text_enabled?
    ENV['RCS_SINGLE_TEXT_ENABLED'].present?
  end

  # Un modèle qui n'appartient à aucun trio (messages « Amont », lus dans l'ENV) est rejoué tel quel.
  def self.rcs_media_id_for_replay(rcs_media_id)
    return rcs_media_id if rcs_media_id.blank?

    bundle = where(rcs_media1_id: rcs_media_id).or(where(rcs_media2_id: rcs_media_id)).or(where(rcs_media3_id: rcs_media_id)).first
    return rcs_media_id unless bundle

    bundle.rcs_media_id_to_send((1..3).find { |index| bundle.public_send("rcs_media#{index}_id").to_s == rcs_media_id.to_s })
  end

  def rcs_media_id_to_send(index)
    return public_send("rcs_media#{index}_id") if public_send("image#{index}_id").present?
    return unless self.class.rcs_single_text_enabled? && long_message?(index)

    public_send("rcs_media#{index}_id")
  end

  def rcs_text_template_missing?(index)
    rcs_media_id_to_send(index).nil? && self.class.rcs_single_text_enabled? && long_message?(index)
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
      rcs_cta_title1: rcs_cta_title1,
      rcs_cta_title2: rcs_cta_title2,
      rcs_cta_title3: rcs_cta_title3,
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

  # ProgramMessageService ajoute ' {URL}' au message avant de mesurer sa taille.
  def long_message?(index)
    body = public_send("body#{index}").to_s
    body += ' {URL}' if public_send("link#{index}_id").present? && body.exclude?('{URL}')
    body.bytesize > MESSAGE_TYPE_MAX_BYTESIZE
  end

  def update_rcs_model1
    service = SpotHit::UpdateRcsModelService.new(text_messages_bundle: self, message_index: 1).call
    Rollbar.error('SpotHit::UpdateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
  end

  def update_rcs_model2
    service = SpotHit::UpdateRcsModelService.new(text_messages_bundle: self, message_index: 2).call
    Rollbar.error('SpotHit::UpdateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
  end

  # Synchronise les modèles RCS SpotHit (messages 1 à 3) après chaque sauvegarde.
  #
  # Pour chaque message dont le contenu (body) est renseigné, trois cas sont gérés :
  # - Le modèle RCS existe mais l'image a été supprimée → planifie la suppression
  #   côté SpotHit dans 2 mois et réinitialise le rcs_media_id.
  # - Le modèle RCS existe et le contenu a changé (body, image ou titre) → met à
  #   jour le modèle via SpotHit::UpdateRcsModelService.
  # - Aucun modèle RCS n'existe encore mais une image est présente → crée le
  #   modèle via SpotHit::CreateRcsModelService.
  #
  # Les erreurs éventuelles sont remontées à Rollbar.
  def sync_rcs_models
    (1..3).each do |index|
      next if send("body#{index}").blank?

      if send("rcs_media#{index}_id").present? && send("image#{index}_id").nil? && !send("rcs_text_template#{index}")
        SpotHit::DeleteRcsModelJob.set(wait_until: 2.months.from_now).perform_later(send("rcs_media#{index}_id"))
        update_column("rcs_media#{index}_id", nil)
      elsif send("rcs_media#{index}_id").present? && (send("saved_change_to_body#{index}?") || send("saved_change_to_image#{index}_id?") || send("saved_change_to_rcs_title#{index}?") || send("saved_change_to_link#{index}_id?") || send("saved_change_to_rcs_cta_title#{index}?"))
        service = SpotHit::UpdateRcsModelService.new(text_messages_bundle: self, message_index: index).call
        Rollbar.error('SpotHit::UpdateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
      elsif send("rcs_media#{index}_id").nil?
        service = SpotHit::CreateRcsModelService.new(text_messages_bundle: self, message_index: index).call
        Rollbar.error('SpotHit::CreateRcsModelService', errors: service.errors, text_messages_bundle_id: id) if service.errors.any?
      end
    end
  end
end
