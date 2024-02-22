class Video::ImportFromAirtableService

  attr_reader :new_videos, :updated_videos

  def initialize
    @airtable_videos = Airtables::Video.all.map { |video| { name: video['Titre'], url: video['lien'] } }
    @new_videos = []
    @updated_videos = []
  end

  def call
    @airtable_videos.each do |airtable_video|
      next unless airtable_video[:url]

      video = Media::Video.find_by(url: airtable_video[:url])
      if video.nil?
        new_video = Media::Video.create!(name: airtable_video[:name], url: airtable_video[:url])
        @new_videos << new_video.id
      elsif video.name != airtable_video[:name]
        video.update!(name: airtable_video[:name])
        @updated_videos << video.id
      end
    end
    self
  end
end
