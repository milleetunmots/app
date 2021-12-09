# Run with rake funders:populate
namespace :typeform do
  desc "Get responses from typeform"
  task get_responses: :environment do
    service = Typeform::GetResponses.new.call
  end
end
