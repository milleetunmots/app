require "rails_helper"

RSpec.describe RedirectionController, type: :request do

  # before do
  #   @video = FactoryBot.build(:media_video)
  #   @redirection_target = RedirectionTarget.create!(medium: @video)
  #   @child = FactoryBot.build(:child)
  #   @redirection_url = RedirectionUrl.create!(
  #     redirection_target: @redirection_target,
  #     parent: @child.parent1,
  #     child: @child
  #   )
  # end
  #
  # it "creates a RedirectionUrlVisit and redirects to the Medium's URL" do
  #   get "/r/#{@redirection_url.id}/#{@redirection_url.security_code}"
  #   expect(response).to redirect_to(@video.url)
  #   expect(@redirection_url.redirection_url_visits.count).to eq(1)
  # end

end
