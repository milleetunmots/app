namespace :support_module do
  desc 'Compte les messages des trios (TextMessagesBundle) des supports modules : ' \
       'messages sans image, et messages sans image ni variable de 160 caractères au plus'
  task count_short_messages: :environment do
    # VARIABLE_REGEX = /\{.*?\}/.freeze
    MAX_LENGTH = 160

    total_messages = 0
    messages_without_image = 0
    short_messages_without_image_nor_variable = 0

    seen_bundle_ids = Set.new

    SupportModule.with_theme_level_and_age_range.find_each do |support_module|
      support_module.support_module_weeks.each do |week|
        [week.medium, week.additional_medium].compact.each do |medium|
          # On ne s'intéresse qu'aux trios de message
          next unless medium.is_a?(Media::TextMessagesBundle)
          # On évite de compter deux fois un même trio partagé entre plusieurs modules
          next unless seen_bundle_ids.add?(medium.id)

          (1..3).each do |index|
            body = medium.public_send("body#{index}")
            next if body.blank?

            total_messages += 1

            has_image = medium.public_send("image#{index}_id").present?
            next if has_image

            messages_without_image += 1

            # has_variable = body.match?(VARIABLE_REGEX)
            # if !has_variable && body.length <= MAX_LENGTH
            if body.length <= MAX_LENGTH
              short_messages_without_image_nor_variable += 1
            end
          end
        end
      end
    end

    puts '------------------------------------------------------------'
    puts "Trios de message parcourus            : #{seen_bundle_ids.size}"
    puts "Messages (body) non vides au total    : #{total_messages}"
    puts "Messages sans image                   : #{messages_without_image}"
    # puts "Messages sans image ni variable ≤ #{MAX_LENGTH} car. : #{short_messages_without_image_nor_variable}"
    puts "Messages sans image ≤ #{MAX_LENGTH} car. : #{short_messages_without_image_nor_variable}"
    puts '------------------------------------------------------------'
  end
end
