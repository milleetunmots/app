class Media::SyncRcsModelsService

  # errors : [message Rollbar, données], remontés par Media::SyncRcsModelsJob.
  attr_reader :errors

  # changed_indexes : messages dont le contenu vient de changer, voir Media::TextMessagesBundle#changed_rcs_message_indexes.
  def initialize(text_messages_bundle, changed_indexes:)
    @bundle = text_messages_bundle
    @changed_indexes = changed_indexes
    @errors = []
  end

  # Un message vidé perd son modèle ; un modèle du mauvais type est remplacé ; un contenu modifié met le modèle à jour ;
  # un message sans modèle en reçoit un.
  def call
    (1..3).each do |index|
      next forget_rcs_model(index) if @bundle.send("body#{index}").blank?

      if rcs_media_id(index).present? && rcs_template_type_outdated?(index)
        replace_rcs_model(index)
      elsif rcs_media_id(index).present? && @changed_indexes.include?(index)
        report('SpotHit::UpdateRcsModelService', SpotHit::UpdateRcsModelService.new(text_messages_bundle: @bundle, message_index: index).call)
      elsif rcs_media_id(index).nil?
        report('SpotHit::CreateRcsModelService', SpotHit::CreateRcsModelService.new(text_messages_bundle: @bundle, message_index: index).call)
      end
    end
    self
  end

  private

  def rcs_media_id(index)
    @bundle.send("rcs_media#{index}_id")
  end

  # Modèle texte avec une image, ou modèle carte sans image : Spot-Hit ne change pas le type d'un modèle.
  def rcs_template_type_outdated?(index)
    @bundle.send("image#{index}_id").present? == @bundle.send("rcs_text_template#{index}")
  end

  # L'ancien modèle n'est supprimé que si le nouveau est accepté ; sinon il continue de servir.
  def replace_rcs_model(index)
    previous_rcs_media_id = rcs_media_id(index)
    service = SpotHit::CreateRcsModelService.new(text_messages_bundle: @bundle, message_index: index).call
    return report('SpotHit::CreateRcsModelService', service) if service.errors.any?
    return if service.rcs_media_id.blank?

    SpotHit::DeleteRcsModelJob.set(wait_until: 2.months.from_now).perform_later(previous_rcs_media_id)
  end

  def forget_rcs_model(index)
    return if rcs_media_id(index).blank?

    SpotHit::DeleteRcsModelJob.set(wait_until: 2.months.from_now).perform_later(rcs_media_id(index))
    @bundle.update_columns("rcs_media#{index}_id" => nil, "rcs_text_template#{index}" => false)
  end

  def report(label, service)
    return if service.errors.empty?

    @errors << [label, { errors: service.errors, text_messages_bundle_id: @bundle.id }]
  end
end
