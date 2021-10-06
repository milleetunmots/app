# Run with rake funders:populate
namespace :spothit do
  desc 'Upload images not present on spothit to spothit'
  task upload_images: :environment do
    Media::Image.where(spot_hit_id: nil).find_each do |image|
      sleep(1)
      service = SpotHit::UploadMediaService.new(image).call
      next if service.errors.any?
      # fail service.errors.join(', ') if service.errors.any?
    end
  end
end
