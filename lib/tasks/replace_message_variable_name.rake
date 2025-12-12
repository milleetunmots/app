namespace :text_messages_bundle do
  desc 'Replace APPELANTE by ACCOMPAGNANTE in text messages bundles bodies'
  task replace_variable: :environment do
    ActiveRecord::Base.transaction do
      Media::TextMessagesBundle.where(
        "body1 LIKE :pattern OR body2 LIKE :pattern OR body3 LIKE :pattern",
        pattern: "%APPELANTE}%"
      ).find_each do |message|
        changed = false
        %i[body1 body2 body3].each do |body_attribute|
          original = message.send(body_attribute)
          next unless original

          new_body = original.gsub('APPELANTE}', 'ACCOMPAGNANTE}')
          if original != new_body
            message.send("#{body_attribute}=", new_body)
            changed = true
            puts "New body: #{new_body}"
          end
        end
        message.save! if changed
      end
    rescue ActiveRecord::RecordInvalid => e
      puts "Erreur : #{e.message}"
      raise ActiveRecord::Rollback
    end
  end
end
