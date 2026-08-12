# == Schema Information
#
# Table name: media
#
#  id             :bigint           not null, primary key
#  body1          :text
#  body2          :text
#  body3          :text
#  discarded_at   :datetime
#  name           :string
#  rcs_cta_title1 :string
#  rcs_cta_title2 :string
#  rcs_cta_title3 :string
#  rcs_title1     :string(200)
#  rcs_title2     :string(200)
#  rcs_title3     :string(200)
#  theme          :string
#  type           :string
#  url            :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  airtable_id    :string
#  folder_id      :bigint
#  image1_id      :bigint
#  image2_id      :bigint
#  image3_id      :bigint
#  link1_id       :bigint
#  link2_id       :bigint
#  link3_id       :bigint
#  rcs_media1_id  :integer
#  rcs_media2_id  :integer
#  rcs_media3_id  :integer
#  spot_hit_id    :string
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

class Medium < ApplicationRecord

  include Discard::Model

  # Types envoyables aux parents via un redirection_target : le message final ne
  # contient que le short link de l'app (toujours autorisé), l'URL cible doit
  # donc être contrôlée ici, à l'entrée dans la médiathèque.
  FOR_REDIRECTION_TYPES = %w[Media::Form Media::Video].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :folder, class_name: :MediaFolder, optional: true
  has_one :redirection_target, dependent: :destroy

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  after_discard do
    redirection_target&.discard
  end

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true
  validates :rcs_title1, :rcs_title2, :rcs_title3, length: { maximum: 200 }, allow_blank: true
  validates :rcs_cta_title1, :rcs_cta_title2, :rcs_cta_title3, length: { maximum: 25 }, allow_blank: true
  # Uniquement quand l'url change : ne pas invalider les médias existants sur une
  # modification sans rapport (nom, tags…).
  validate :url_must_be_allowed, if: -> { url_changed? && url.present? && type.in?(FOR_REDIRECTION_TYPES) }

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :without_folder, -> { where(folder: nil) }
  scope :documents, -> { where(type: "Media::Document") }
  scope :forms, -> { where(type: "Media::Form") }
  scope :images, -> { where(type: "Media::Image") }
  scope :videos, -> { where(type: "Media::Video") }
  scope :text_messages_bundles, -> { where(type: "Media::TextMessagesBundle") }
  scope :text_messages_bundle_drafts, -> { where(type: "Media::TextMessagesBundleDraft") }

  scope :for_redirections, -> {
    where(type: FOR_REDIRECTION_TYPES)
  }

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  # Médias dont l'url serait refusée par le filtre. Le filtrage se fait en Ruby
  # (les patterns ne sont pas exprimables en SQL), d'où un tableau et non un scope.
  def self.refused_by_url_filter
    patterns = AllowedPattern.where(kind: 'url').to_a

    for_redirections.kept.where.not(url: [nil, '']).reject do |medium|
      AllowedPattern.url_allowed?(medium.url, patterns: patterns)
    end
  end

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

  private

  # Volontairement générique, comme BlockedSendAttempt::SendGuard::BLOCKED_MESSAGE :
  # ne rien dire du mécanisme ni de la façon d'y échapper. La médiathèque est
  # accessible aux contributeurs, qui n'ont pas accès aux patterns autorisés.
  def url_must_be_allowed
    return if AllowedPattern.url_allowed?(url)

    # Mode surveillance : on laisse passer, mais on trace. L'url cible n'apparaît
    # jamais dans le message envoyé (le parent reçoit le short link de l'app), le
    # guard d'envoi ne peut donc pas la voir : sans cette alerte, rien ne signale
    # le problème avant l'activation du filtre.
    unless BlockedSendAttempt::UrlSendGuard.blocking_enabled?
      Rollbar.warning('Medium : url qui serait refusée par le filtre', medium_id: id, type: type, name: name, url: url)
      return
    end

    errors.add(:url, 'ne peut pas être enregistrée, veuillez contacter le pôle tech.')
  end

end
