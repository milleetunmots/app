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

      video = Media::Video.find_by(airtable_id: airtable_video[:id])
      if video.nil?
        new_video = Media::Video.create!(airtable_id: airtable_video[:id].strip, name: airtable_video[:name].strip, url: airtable_video[:url].strip)
        @new_videos << new_video.id
      elsif airtable_video[:name].strip != video.name.strip || airtable_video[:url].strip != video.url.strip
        video.update!(name: airtable_video[:name].strip, url: airtable_video[:url].strip)
        @updated_videos << video.id
      end
    end
    self
  end
end
