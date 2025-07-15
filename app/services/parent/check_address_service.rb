require 'csv'

class Parent::CheckAddressService

  MESSAGE = "1001mots : Vous n'avez pas reçu votre dernier livre ? Vérifiez votre adresse sur ce lien :".freeze

  attr_reader :errors

  def initialize(csv_file)
    @message = "#{MESSAGE} https://form.typeform.com/to/#{ENV['UPDATING_ADDRESS_TYPEFORM_ID']}#st=xxxxx"
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
        "TRIM(LOWER(unaccent(REPLACE(REPLACE(address, ',', ''), '.', '')))) ILIKE unaccent(REPLACE(REPLACE(?, ',', ''), '.', '')) AND
         TRIM(LOWER(unaccent(REPLACE(postal_code::text, '.', '')))) ILIKE unaccent(REPLACE(?, '.', '')) AND
         TRIM(LOWER(unaccent(letterbox_name))) ILIKE unaccent(?)", address, postal_code, letterbox_name).first
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
    message = @message.gsub('st=xxxxx', "st=#{parent.security_token}")
    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{parent.id}"],
      message
    ).call
    @errors << "Address Verification message not sent to #{parent.first_name} #{parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end
end
