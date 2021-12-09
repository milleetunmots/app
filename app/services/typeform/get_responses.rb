class Typeform::GetResponses

  attr_reader :errors

  def initialize
    @uri = URI("https://api.typeform.com/forms/#{ENV["WELCOME_TYPEFORM_ID"]}/responses?page_size=1000")
  end

  def call
    response = HTTP.auth("Bearer #{ENV["TYPEFORM_TOKEN"]}").get(@uri)
    return unless response.status.success?

    answers = JSON.parse(response.body.to_s)["items"]

    answers.each do |item|
      answer = item["answers"]
      response_id = item["response_id"]

      unless WelcomeFormResponse.where(response_id: response_id).exists?
        WelcomeFormResponse.create(response_id: response_id,
                                   form_item: answer)
      end
    end
    self
  end
end
