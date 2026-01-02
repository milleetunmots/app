namespace :rcs do
  desc "Create RCS templates for all TextMessagesBundle with images"
  task create_templates: :environment do
    puts "Starting RCS template creation..."

    bundles = Media::TextMessagesBundle.kept.all
    total = bundles.count
    success_count = 0
    error_count = 0
    skipped_count = 0

    bundles.each_with_index do |bundle, index|
      puts "\n[#{index + 1}/#{total}] Processing bundle ##{bundle.id} - #{bundle.name}"

      # process each message in the bundle (1, 2, 3)
      [1, 2, 3].each do |message_index|
        body = bundle.send("body#{message_index}")
        image_id = bundle.send("image#{message_index}_id")
        rcs_media_id = bundle.send("rcs_media#{message_index}_id")

        if body.blank?
          puts "Message #{message_index}: skipped (no body)"
          next
        end

        if rcs_media_id.present?
          puts "Message #{message_index}: skipped (RCS template already exists with ID #{rcs_media_id})"
          skipped_count += 1
          next
        end

        if image_id.blank?
          puts "Message #{message_index}: warning (no image attached)"
        end

        # create RCS template
        service = SpotHit::CreateRcsModelService.new(
          text_messages_bundle: bundle,
          message_index: message_index
        ).call

        if service.errors.any?
          puts "Message #{message_index}: ERROR - #{service.errors.join(', ')}"
          error_count += 1
        else
          puts "Message #{message_index}: SUCCESS - RCS template ID #{service.rcs_media_id}"
          success_count += 1
        end

        # avoid rate limiting
        sleep 0.5
      end
    end

    puts "\n" + "="*10
    puts "Results:"
    puts "Total bundles processed: #{total}"
    puts "Templates created: #{success_count}"
    puts "Templates skipped: #{skipped_count}"
    puts "Errors: #{error_count}"
  end

  desc "Create RCS template for a specific TextMessagesBundle and message index"
  task :create_template, [:bundle_id, :message_index] => :environment do |t, args|
    bundle_id = args[:bundle_id]
    message_index = args[:message_index]&.to_i || 1

    unless bundle_id.present?
      puts "Usage: rake rcs:create_template[BUNDLE_ID,MESSAGE_INDEX]"
      exit 1
    end

    bundle = Media::TextMessagesBundle.find_by(id: bundle_id)
    unless bundle
      puts "ERROR: Bundle ##{bundle_id} not found"
      exit 1
    end

    puts "Creating RCS template for bundle ##{bundle_id} - #{bundle.name}, message #{message_index}..."

    service = SpotHit::CreateRcsModelService.new(
      text_messages_bundle: bundle,
      message_index: message_index
    ).call

    if service.errors.any?
      puts "ERROR: #{service.errors.join(', ')}"
      exit 1
    else
      puts "SUCCESS: RCS template created with ID #{service.rcs_media_id}"
      puts "Saved to rcs_media#{message_index}_id column"
    end
  end
end
