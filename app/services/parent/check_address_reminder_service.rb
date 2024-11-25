require 'csv'

class Parent::CheckAddressReminderService

  attr_reader :errors

  def initialize
    @message = "#{Parent::CheckAddressService::MESSAGE} https://form.typeform.com/to/VpPCzGfD#parent_id=xxxxx&security_code=xxxxx"
    @errors = []
    @date = Time.zone.now
  end

  def call
    ChildSupport.joins(:children).where(is_address_suspected_invalid: true, children: { group_status: 'active' }).find_each do |child_support|
      @parent = child_support.parent1
      next if @parent.message_already_sent?(6.days.ago, Parent::CheckAddressService::MESSAGE)

      send_verifiication_message
    end
    self
  end

  private

  def send_verifiication_message
    @message = @message.gsub('parent_id=xxxxx', "parent_id=#{@parent.id}")
    @message = @message.gsub('security_code=xxxxx', "security_code=#{@parent.security_code}")
    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      @message
    ).call
    @errors << "Verification message reminder not sent to #{@parent.first_name} #{@parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end
end
