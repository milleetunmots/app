namespace :video do
  desc 'Add airtable_id to videos'
  task add_airtable_id: :environment do
    airtable_videos = Airtables::Url.all

    video_ids = []

    airtable_videos.each do |airtable_video|
      next unless airtable_video['Lien URL final']

      if Media::Video.where(name: airtable_video['Nom URL base Yann']).count > 1
        video_ids << Media::Video.where(name: airtable_video['Nom URL base Yann']).pluck(:id)
      end

      next if Media::Video.where(name: airtable_video['Nom URL base Yann']).count > 1

      video = Media::Video.find_by(name: airtable_video['Nom URL base Yann'])
      next unless video

      next if video.airtable_id

      video.update!(airtable_id: airtable_video.id)
    end

    p video_ids
  end
end
