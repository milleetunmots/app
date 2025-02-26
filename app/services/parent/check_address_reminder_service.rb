require 'csv'

class Parent::CheckAddressReminderService

  attr_reader :errors

  def initialize
    @message = "#{Parent::CheckAddressService::MESSAGE} https://form.typeform.com/to/#{ENV['UPDATING_ADDRESS_TYPEFORM_ID']}#parent_id=xxxxx&sc=xxxxx"
    @errors = []
    @date = Time.zone.now
  end

  def call
    ChildSupport.joins(:children).where.not(address_suspected_invalid_at: nil).where(children: { group_status: 'active' }).find_each do |child_support|
      @parent = child_support.parent1
      next if @parent.message_already_sent?(6.days.ago, Parent::CheckAddressService::MESSAGE)

      send_verification_message
    end
    self
  end

  private

  def send_verification_message
    @message = @message.gsub('parent_id=xxxxx', "parent_id=#{@parent.id}")
    @message = @message.gsub('sc=xxxxx', "sc=#{@parent.security_code}")
    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      @message
    ).call
    @errors << "Address Verification message reminder not sent to #{@parent.first_name} #{@parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end
end
