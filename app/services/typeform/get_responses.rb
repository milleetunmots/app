class Typeform::GetResponses

  attr_reader :errors

  def initialize
    @errors = []
    @uri = URI("https://api.typeform.com/forms/#{ENV["WELCOME_TYPEFORM_ID"]}/responses?page_size=1000")
    @result = {}
  end

  def call
    response = HTTP.auth("Bearer #{ENV["TYPEFORM_TOKEN"]}").post(@uri)
    byebug
    self
  end
end
