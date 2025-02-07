class Parent::ProgramSmsToVerifyAdressService

  MESSAGE = "1001mots : Boujour, nous allons bientôt envoyer un livre pour {PRENOM_ENFANT}. Nous allons l'envoyer à l'adresse suivante : {ADDRESS}. Si l'adresse postale ou le nom sur la boîte aux lettre ne sont pas bons, merci de les modifier ici :".freeze

  attr_reader :errors

  def initialize(group_id)
    @message = "#{MESSAGE} https://form.typeform.com/to/VpPCzGfD#parent_id=xxxxx&security_code=xxxxx"
    @errors = []
    @date = Time.zone.now
  end

  def call
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
