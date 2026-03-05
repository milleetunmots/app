class SpotHit::UpdateRcsModelService < SpotHit::CreateRcsModelService

  URL = 'https://www.spot-hit.fr/api/rcs/model/modify'.freeze

  attr_reader :errors

  def initialize(text_messages_bundle:, message_index:)
    super
    @rcs_media_id = @text_messages_bundle.send("rcs_media#{message_index}_id")
  end

  def call
    validate_params
    return self if @errors.any?

    push_rcs_template
    self
  end

  private

  def validate_params
    super
    @errors << "rcs_media#{@message_index}_id is blank, cannot modify RCS template" if @rcs_media_id.blank?
  end

  def push_rcs_template
    download_image_to_tmp_file
    response = HTTP.post(URL, form: form_data)
    parsed_response = JSON.parse(response.body.to_s)

    if parsed_response['success'] == false
      error_message = parsed_response['error']&.dig('message') || response.body.to_s
      @errors << "Erreur lors de la modification du modèle RCS: #{error_message}"
    end
  rescue => e
    @errors << "Exception lors de la modification du modèle RCS: #{e.message}"
  ensure
    remove_tmp_file(@tmp_file) if @tmp_file && File.exist?(@tmp_file)
  end

  def form_data
    form = super
    form['id'] = @rcs_media_id
    form
  end
end
