class SpotHit::UploadMediaService

  attr_reader :errors

  def initialize(media)
    @errors = []
    @uri = URI('https://www.spot-hit.fr/api/mms/upload')
    @media = media
  end

  def call
    tmp_file_path =
      if @media.attachment_changes['file'].present?
        # when this service is called from after_save, we have access to a tmp file
        # so we dont need to create a new one
        @media.attachment_changes['file'].attachable.tempfile
      else
        download_media_to_tmp_file(@media)
      end

    response = HTTP.post(
      @uri,
      form: {
        key: ENV["SPOT_HIT_API_KEY"],
        fichier: HTTP::FormData::File.new(tmp_file_path)
      }
    )

    # remove file only if we created it
    remove_tmp_file(tmp_file_path) unless @media.attachment_changes['file'].present?

    parsed_response = JSON.parse(response.body.to_s)

    if parsed_response['success'] == true && parsed_response['file'].present?
      @media.update_columns(spot_hit_id: parsed_response['file'])
    else
      @errors << "Erreur lors de l'upload de l'image sur Spot Hit"
    end
    self
  end

  def download_media_to_tmp_file(media)
    tmp_file = "#{Dir.tmpdir}/#{media.file.filename}"
    File.open(tmp_file, 'wb') do |file|
       file.write(media.file.download)
    end
    tmp_file
  end

  def remove_tmp_file(path)
    File.delete(path)
  end
end
