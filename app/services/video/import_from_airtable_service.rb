class Video::ImportFromAirtableService

  attr_reader :new_videos, :updated_videos

  def initialize
    @airtable_videos = Airtables::Url.all.map { |video| { id: video.id, name: video['Nom URL base Yann'], url: video['Lien URL cible'] } }
    @new_videos = []
    @updated_videos = []
  end

  def call
    @airtable_videos.each do |airtable_video|
      next if airtable_video[:url].nil? || airtable_video[:name].nil?

      video = Media::Video.find_by(airtable_id: airtable_video[:id])
      if video.nil?
        new_video = Media::Video.create!(airtable_id: airtable_video[:id], name: airtable_video[:name], url: airtable_video[:url])
        @new_videos << new_video.id
      elsif video.name != airtable_video[:name]
        video.update!(name: airtable_video[:name])
        @updated_videos << video.id
      end
    end
    self
  end
end
