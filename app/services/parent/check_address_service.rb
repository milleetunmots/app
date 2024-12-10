require 'csv'

class Parent::CheckAddressService

  MESSAGE = "1001mots : Vous n'avez pas reçu votre dernier livre ? Vérifiez votre adresse sur ce lien :".freeze

  attr_reader :errors

  def initialize(csv_file)
    @message = "#{MESSAGE} https://form.typeform.com/to/VpPCzGfD#parent_id=xxxxx&security_code=xxxxx"
    @lines = CSV.read(csv_file)
    @errors = []
    @date = Time.zone.now
  end

  def call
    @lines.each do |line|
      @address = line[4]
      @postal_code = line[6]
      @city_name = line[7]

      @parent = Parent.where('TRIM(LOWER(unaccent(address))) ILIKE TRIM(LOWER(unaccent(?))) AND TRIM(LOWER(unaccent(postal_code))) ILIKE TRIM(LOWER(unaccent(?))) AND TRIM(LOWER(unaccent(city_name))) ILIKE TRIM(LOWER(unaccent(?)))', "%#{@address}%", "%#{@postal_code}%", "%#{@city_name}%").first
      next unless @parent

      @child_support = @parent.current_child&.child_support
      unless @child_support
        @errors << "Aucune fiche de suivi n'est lié à #{@parent.first_name} #{@parent.last_name}"
        next
      end

      next if @child_support.address_suspected_invalid_at.present?

      @child_support.update(address_suspected_invalid_at: Time.zone.now)
      send_verification_message
    end
    Parent::CheckAddressReminderJob.set(wait_until: @date.next_day(7).to_datetime.change(hour: 13)).perform_later
    self
  end

  private

  def send_verification_message
    @message = @message.gsub('parent_id=xxxxx', "parent_id=#{@parent.id}")
    @message = @message.gsub('security_code=xxxxx', "security_code=#{@parent.security_code}")
    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      @message
    ).call
    @errors << "Address Verification message not sent to #{@parent.first_name} #{@parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end
end
