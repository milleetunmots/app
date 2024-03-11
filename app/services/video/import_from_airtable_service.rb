class Video::ImportFromAirtableService

  attr_reader :new_videos, :updated_videos

  def initialize
    @airtable_videos = Airtables::Url.verified.map { |video| { id: video.id, name: video['Nom URL base Yann'], url: video['Lien URL final'] } }
    @new_videos = []
    @updated_videos = []
  end

  def call
    @airtable_videos.each do |airtable_video|
      next if airtable_video[:url].nil? || airtable_video[:name].nil?
      video_url = airtable_video[:url].first.strip
      video_name = airtable_video[:name].first.strip

      video = Media::Video.find_by(airtable_id: airtable_video[:id])
      if video.nil?
        new_video = Media::Video.create!(airtable_id: airtable_video[:id].strip, name: video_name, url: video_url)
        @new_videos << new_video.id
      elsif video_name != video.name.strip || video_url != video.url.strip
        video.update!(name: video_name, url: video_url)
        @updated_videos << video.id
      end
    end
    self
  end
end
