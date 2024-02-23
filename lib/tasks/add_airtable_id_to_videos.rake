namespace :video do
  desc 'Add airtable_id to videos'
  task add_airtable_id: :environment do
    airtable_videos = Airtables::Video.all

    airtable_videos.each do |airtable_video|
      next unless airtable_video['lien']

      next if Media::Video.where(url: airtable_video['lien']).count > 1

      video = Media::Video.find_by(url: airtable_video['lien'])
      next unless video

      next if video.airtable_id

      video.update!(airtable_id: airtable_video.id)
    end
  end
end
