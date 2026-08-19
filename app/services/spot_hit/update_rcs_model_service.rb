class SpotHit::UpdateRcsModelService < SpotHit::CreateRcsModelService

  URL = 'https://www.spot-hit.fr/api/rcs/model/modify'.freeze

  attr_reader :errors

  def initialize(text_messages_bundle:, message_index:)
    super
    @rcs_media_id = @text_messages_bundle.send("rcs_media#{message_index}_id")
  end

  def call
    return self if Rails.env.development? || ENV['SPOT_HIT_SAFEGUARD'].present?

    validate_params
    return self if @errors.any?

    # Même contrôle qu'à la création (cf. CreateRcsModelService#check_template_content) :
    # sans ça, on peut créer un template propre puis l'éditer pour y mettre
    # n'importe quel contenu, qui repartira tel quel à chaque envoi RCS.
    check_template_content
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
    parsed_response = parse_json_response(response)
    failed = !parsed_response.is_a?(Hash) || parsed_response['success'] == false

    @errors << "Erreur lors de la modification du modèle RCS: #{json_error_message(response, parsed_response)}" if failed
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
