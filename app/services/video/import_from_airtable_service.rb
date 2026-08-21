class Video::ImportFromAirtableService

  attr_reader :new_videos, :updated_videos, :errors

  def initialize
    @airtable_videos = Airtables::Url.verified.map { |video| { id: video.id, name: video['Nom URL base Yann'], url: video['Lien URL final'] } }
    @new_videos = []
    @updated_videos = []
    @errors = []
  end

  # Une vidéo en échec (url refusée par la validation AllowedPattern, par ex.)
  # ne doit pas interrompre l'import : sans ce rescue, toutes les vidéos suivantes
  # étaient silencieusement ignorées.
  def call
    @airtable_videos.each do |airtable_video|
      next if airtable_video[:url].nil? || airtable_video[:name].nil?
      video_url = airtable_video[:url].first.strip
      video_name = airtable_video[:name].first.strip

      import_video(airtable_video[:id], video_name, video_url)
    end
    Rollbar.error('Video::ImportFromAirtableService', errors: @errors) if @errors.any?
    self
  end

  private

  def import_video(airtable_id, video_name, video_url)
    video = Media::Video.find_by(airtable_id: airtable_id)
    if video.nil?
      new_video = Media::Video.create!(airtable_id: airtable_id.strip, name: video_name, url: video_url)
      @new_videos << new_video.id
    elsif video_name != video.name.strip || video_url != video.url.strip
      video.update!(name: video_name, url: video_url)
      @updated_videos << video.id
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << { airtable_id: airtable_id, name: video_name, errors: e.record.errors.full_messages }
  end
end
