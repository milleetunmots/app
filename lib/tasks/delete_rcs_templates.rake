namespace :rcs do
  desc "Delete RCS templates"
  task delete_templates: :environment do
    puts "Starting RCS template deletion..."

    bundles = Media::TextMessagesBundle.kept.all
    rcs_media_ids =
      bundles.where.not(rcs_media1_id: nil).pluck(:rcs_media1_id) +
      bundles.where.not(rcs_media2_id: nil).pluck(:rcs_media2_id) +
      bundles.where.not(rcs_media3_id: nil).pluck(:rcs_media3_id)
    total = rcs_media_ids.count
    success_count = 0
    error_count = 0

    rcs_media_ids.each_with_index do |rcs_media_id, index|
      puts "\n[#{index + 1}/#{total}] Deleting model ##{rcs_media_id}"

      service = SpotHit::DeleteRcsModelService.new(
        rcs_media_id: rcs_media_id,
      ).call

      sleep 0.5

      if service.errors.any?
        puts "Model #{rcs_media_id} deletion : ERROR"
        error_count += 1
      else
        puts "Model #{rcs_media_id}: deletion : SUCCESS"
        success_count += 1
      end
    end
    puts "\n" + "="*10
    puts "Results:"
    puts "Total bundles processed: #{total}"
    puts "Templates created: #{success_count}"
    puts "Errors: #{error_count}"
  end
end
