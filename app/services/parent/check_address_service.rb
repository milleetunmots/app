require 'csv'

class Parent::CheckAddressService

  MESSAGE = "1001mots : Vous n'avez pas reçu votre dernier livre ? Vérifiez votre adresse sur ce lien :".freeze
  NAME = "Demande de vérification d'adresse (PND)".freeze
  KEY = 'verification_adresse_pnd'.freeze

  attr_reader :errors, :missing_bundle_error

  def initialize(csv_file)
    @lines = CSV.read(csv_file)
    @errors = []
    @date = Time.zone.now
  end

  def call
    @lines.each do |line|
      letterbox_name = line[3].present? ? "%#{line[3].strip.downcase}%" : nil
      address = line[4].present? ? "%#{line[4].strip.downcase}%" : nil
      postal_code = line[6].present? ? "%#{line[6].strip.downcase}%" : nil
      city_name = line[7].present? ? "%#{line[7].strip.downcase}%" : nil

      parent = Parent.with_a_child_in_active_group.where(
        "TRIM(LOWER(unaccent(regexp_replace(address, '[^a-zA-Z0-9]', '', 'g')))) ILIKE unaccent(regexp_replace(?, '[^a-zA-Z0-9]', '', 'g')) AND
          TRIM(LOWER(regexp_replace(postal_code::text, '[^a-zA-Z0-9]', '', 'g'))) ILIKE regexp_replace(?, '[^a-zA-Z0-9]', '', 'g') AND
         TRIM(LOWER(unaccent(letterbox_name))) ILIKE unaccent(?) AND
         TRIM(LOWER(unaccent(REPLACE(REPLACE(city_name, '-', ''), ' ', '')))) ILIKE unaccent(REPLACE(REPLACE(?, '-', ''), ' ', ''))", address, postal_code, letterbox_name, city_name
      ).first
      next unless parent
      next if parent.book_delivery_location_different_from_home?

      child_support = parent.current_child&.child_support
      unless child_support
        @errors << "Aucune fiche de suivi n'est lié à #{parent.first_name} #{parent.last_name}"
        next
      end

      next if child_support.address_suspected_invalid_at.present?

      child_support.update(address_suspected_invalid_at: Time.zone.now)
      send_verification_message(parent)
    end
    Parent::CheckAddressReminderJob.set(wait_until: @date.next_day(7).to_datetime.change(hour: 13)).perform_later
    self
  end

  private

  def send_verification_message(parent)
    return report_missing_bundle unless bundle

    service = ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{parent.id}"],
      bundle.body1.dup,
      bundle.rcs_media_id_to_send(1),
      link_id,
      automatic_message_key: KEY
    ).call
    @errors << "Address Verification message not sent to #{parent.first_name} #{parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end

  # Cherché au premier parent à prévenir, une seule fois : un fichier sans parent retrouvé ne cherche aucun trio.
  def bundle
    return @bundle if defined?(@bundle)

    @bundle = Media::TextMessagesBundle.find_automatic(name: NAME, key: KEY)
  end

  def link_id
    RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id if bundle.link1_id
  end

  def report_missing_bundle
    return if @missing_bundle_error

    @missing_bundle_error = "Trio introuvable : « #{NAME} » (clé #{KEY}), message non envoyé"
    @errors << @missing_bundle_error
  end
end
