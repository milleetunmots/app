require 'csv'

class Parent::CheckAddressReminderService

  attr_reader :errors

  def initialize
    @message = "#{Parent::CheckAddressService::MESSAGE} https://form.typeform.com/to/#{ENV['UPDATING_ADDRESS_TYPEFORM_ID']}#st=xxxxx"
    @errors = []
    @date = Time.zone.now
  end

  def call
    ChildSupport.joins(:children).where.not(address_suspected_invalid_at: nil).where(children: { group_status: 'active' }).find_each do |child_support|
      parent = child_support.parent1
      next if parent.book_delivery_location_different_from_home?
      next if parent.message_already_sent?(6.days.ago, Parent::CheckAddressService::MESSAGE)

      send_verification_message(parent)
    end
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
    @errors << "Address Verification message reminder not sent to #{parent.first_name} #{parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end
end
