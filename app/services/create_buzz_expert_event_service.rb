class CreateBuzzExpertEventService

  attr_reader :errors, :event

  def initialize(phone_number:, body:)
    @phone_number = phone_number
    @body = body
    @errors = []
  end

  def call
    puts "Processing BuzzExpert SMS from #{@phone_number}: #{@response}"

    found_parent = find_parent
    @errors << "Unable to find parent" and return self unless found_parent

    event = Events::TextMessage.new(
      related: found_parent,
      body: @body,
      occurred_at: Time.now,
      originated_by_app: false
    )
    @errors += event.errors.full_messages and return self unless event.save

    self
  end

  private

  def find_parent
    parsed_phone = Phonelib.parse(@phone_number)
    parsed_phone && Parent.where(phone_number: parsed_phone.e164).first
  end

end
