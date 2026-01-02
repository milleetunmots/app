class SpotHit::CreateRcsModelService

  URL = 'https://www.spot-hit.fr/api/rcs/model/create'.freeze

  attr_reader :errors, :rcs_media_id

  # message_index: 1, 2, or 3 (which message from the bundle to create)
  def initialize(text_messages_bundle:, message_index:)
    @text_messages_bundle = text_messages_bundle
    @message_index = message_index
    @errors = []
    @rcs_media_id = nil
  end

  def call
    validate_params
    return self if @errors.any?

    create_rcs_template
    save_rcs_media_id if @errors.empty? && @rcs_media_id.present?
    self
  end

  private

  def validate_params
    unless [1, 2, 3].include?(@message_index)
      @errors << "message_index must be 1, 2, or 3"
      return
    end

    if body.blank?
      @errors << "body#{@message_index} is blank, cannot create RCS template"
      return
    end

    if image.blank?
      @errors << "image#{@message_index} is blank, cannot create RCS template"
    end
  end

  def body
    @body ||= begin
      raw_body = @text_messages_bundle.send("body#{@message_index}")
      clean_body(raw_body)
    end
  end

  def image
    @image ||= begin
      image_id = @text_messages_bundle.send("image#{@message_index}_id")
      return nil if image_id.nil?
      Media::Image.find_by(id: image_id)
    end
  end

  def create_rcs_template
    # RCS model JSON structure
    model_json = {
      "content" => {
        "card" => {
          "title" => "1001mots",
          "text" => body,
          "mediaType" => "image",
          "file" => "{cid:image}",
          "buttons" => [],
          "suggestions" => [],
          "options" => []
        },
        "property" => {
          "stop" => true
        }
      }
    }

    form_data = {
      'key' => ENV['SPOT_HIT_API_KEY'],
      'model' => model_json.to_json
    }

    # add image file
    if image&.file&.attached?
      tmp_file_path = download_image_to_tmp_file
      form_data['{cid:image}'] = HTTP::FormData::File.new(tmp_file_path, content_type: image.file.content_type)
    end

    begin
      # SpotHit has CRL issues that cause SSL errors in some dev environments
      # skip SSL verification in development only (works fine in production/staging)
      if Rails.env.development?
        ssl_ctx = OpenSSL::SSL::SSLContext.new
        ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = HTTP.post(URL, form: form_data, ssl_context: ssl_ctx)
      else
        response = HTTP.post(URL, form: form_data)
      end
      parsed_response = JSON.parse(response.body.to_s)

      if parsed_response['success'] == true && parsed_response['id'].present?
        @rcs_media_id = parsed_response['id']
      else
        error_message = parsed_response['error']&.dig('message') || response.body.to_s
        @errors << "Erreur lors de la création du modèle RCS: #{error_message}"
      end
    rescue => e
      @errors << "Exception lors de la création du modèle RCS: #{e.message}"
    ensure
      # clean up tmp file if it was created
      remove_tmp_file(tmp_file_path) if tmp_file_path && File.exist?(tmp_file_path)
    end
  end

  def save_rcs_media_id
    column_name = "rcs_media#{@message_index}_id"
    @text_messages_bundle.update_column(column_name, @rcs_media_id)
    Rails.logger.info "Saved RCS media ID #{@rcs_media_id} to #{column_name} for TextMessagesBundle ##{@text_messages_bundle.id}"
  end

  def clean_body(raw_body)
    return raw_body if raw_body.blank?

    # remove "1001mots :" and variations from the beginning
    cleaned = raw_body.gsub(/\A\s*1001\s*mots\s*:?\s*/i, '').strip
    return cleaned if cleaned.blank?
    # capitalize first letter
    cleaned = raw_body.gsub(/\A\s*1001\s*mots\s*:?\s*/i, '')
    cleaned[0].upcase + cleaned[1..-1]
  end

  def download_image_to_tmp_file
    return nil unless image&.file&.attached?

    tmp_file = "#{Dir.tmpdir}/rcs_#{@text_messages_bundle.id}_#{@message_index}_#{image.file.filename}"
    File.open(tmp_file, 'wb') do |file|
      file.write(image.file.download)
    end
    tmp_file
  end

  def remove_tmp_file(path)
    File.delete(path) if path && File.exist?(path)
  rescue => e
    Rails.logger.warn "Failed to remove tmp file #{path}: #{e.message}"
  end
end
