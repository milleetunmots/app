class Parent::ProgramSmsToVerifyAddressService

  MESSAGE = "1001mots : Bonjour, nous allons bientôt envoyer un livre pour {PRENOM_ENFANT}. Nous allons l'envoyer à l'adresse suivante : {ADDRESS}Si l'adresse postale ou le nom sur la boîte aux lettres ne sont pas bons, merci de les modifier ici :".freeze

  attr_reader :errors

  def initialize(group_id, program_sms_date)
    @errors = []
    @children = Group.find(group_id).children.where(group_status: 'active', should_contact_parent1: true)
    @date = program_sms_date
  end

  def call
    @children.find_each do |child|
      @parent = child.parent1
      address = "\n#{@parent.letterbox_name}\n#{@parent.address}\n"
      address = "#{address}#{@parent.address_supplement}\n" unless @parent.address_supplement.blank?
      address = "#{address}#{@parent.postal_code} #{@parent.city_name}\n"
      @message = "#{MESSAGE} https://form.typeform.com/to/#{ENV['UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID']}#parent_id=xxxxx&security_code=xxxxx".gsub('{ADDRESS}', address)
      @message = @message.gsub('parent_id=xxxxx', "parent_id=#{@parent.id}")
      @message = @message.gsub('security_code=xxxxx', "security_code=#{@parent.security_code}")
      service = ProgramMessageService.new(
        @date.strftime('%d-%m-%Y'),
        @date.strftime('%H:%M'),
        ["parent.#{@parent.id}"],
        @message
      ).call
      @errors << { service: 'ProgramMessageService', parent_id: @parent.id, parent_phone_number: @parent.phone_number, errors: service.errors } if service.errors.any?
    end
    self
  end
end
