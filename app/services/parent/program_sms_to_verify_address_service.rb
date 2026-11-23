class Parent::ProgramSmsToVerifyAddressService

  BUNDLE = ["Vérification de l'adresse", 'verification_adresse'].freeze

  attr_reader :errors

  def initialize(group_id, program_sms_date)
    @errors = []
    @children = Group.find(group_id).children.where(group_status: 'active', should_contact_parent1: true)
    @date = program_sms_date
  end

  def call
    @children.find_each do |child|
      @parent = child.parent1
      next if @parent.book_delivery_location_different_from_home?

      service = program_message(child)
      next unless service

      @errors << { service: 'ProgramMessageService', parent_id: @parent.id, parent_phone_number: @parent.phone_number, errors: service.errors } if service.errors.any?
    end
    self
  end

  private

  def program_message(child)
    return report_missing_bundle unless bundle

    ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'), @date.strftime('%H:%M'), ["parent.#{@parent.id}"],
      bundle.body1, bundle.rcs_media_id_to_send(1), bundle.redirection_target_id(1),
      automatic_message_key: BUNDLE.last,
      recipient_variables: { @parent.id => { 'PARENT_ADDRESS' => address_block, 'PRENOM_ENFANT' => child.first_name } }
    ).call
  end

  # Bloc sur plusieurs lignes, comme avant le trio, et non l'adresse sur une ligne de ProgramMessageService.
  def address_block
    lines = [*addressee, @parent.address, @parent.address_supplement.presence, "#{@parent.postal_code} #{@parent.city_name}"]
    "\n#{lines.compact.join("\n")}"
  end

  def addressee
    case @parent.book_delivery_location
    when nil, 'home' then [@parent.letterbox_name]
    when 'relative_home' then [@parent.letterbox_name, @parent.attention_to]
    else [@parent.book_delivery_organisation_name, @parent.attention_to]
    end
  end

  def bundle
    return @bundle if defined?(@bundle)

    @bundle = Media::TextMessagesBundle.find_automatic(name: BUNDLE.first, key: BUNDLE.last)
  end

  def report_missing_bundle
    return if @missing_bundle_reported

    @missing_bundle_reported = true
    @errors << Media::TextMessagesBundle.missing_message(name: BUNDLE.first, key: BUNDLE.last)
    nil
  end
end
