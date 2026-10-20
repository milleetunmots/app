require "rails_helper"

RSpec.describe RedirectionController, type: :request do

  before do
    @video = FactoryBot.create(:media_video)
    @redirection_target = RedirectionTarget.find_by(medium: @video)
    @child = FactoryBot.build(:child)
    @redirection_url = RedirectionUrl.create!(
      redirection_target: @redirection_target,
      parent: @child.parent1,
      child: @child
    )
  end

  it "creates a RedirectionUrlVisit and redirects to the Medium's URL" do
    get "/r/#{@redirection_url.id}/#{@redirection_url.security_code}"
    expect(response).to redirect_to(@video.url)
    expect(@redirection_url.redirection_url_visits.count).to eq(1)
  end

  describe "url de destination" do
    let(:child_support_id) { @redirection_url.child.child_support_id }

    # update_column : on teste la redirection, pas le filtre d'urls des médias
    def redirect_location_for(medium_url)
      @video.update_column(:url, medium_url)
      get "/r/#{@redirection_url.id}/#{@redirection_url.security_code}"
      response.location
    end

    it "ne réencode pas les paramètres déjà encodés (%2C ne devient pas %252C)" do
      url = 'https://leseldanslecafe.fr/?lat=47%2C9339567&lng=1%2C9169628&type=Structure&fiche=les-petites-bulles'

      expect(redirect_location_for(url)).to eq(url)
    end

    it "encode une seule fois les accents et les espaces" do
      expect(redirect_location_for('https://exemple.fr/page?x=café et thé'))
        .to eq('https://exemple.fr/page?x=caf%C3%A9%20et%20th%C3%A9')
    end

    it "conserve l'ancre" do
      expect(redirect_location_for('https://exemple.fr/page?x=1#section')).to eq('https://exemple.fr/page?x=1#section')
    end

    context "avec une url Bubble" do
      it "ajoute child_support_id sans réencoder les paramètres existants" do
        expect(redirect_location_for('https://1001mots-app1.bubbleapps.io/version-test/form?lat=47%252C9&next=/a/b'))
          .to eq("https://1001mots-app1.bubbleapps.io/version-test/form?lat=47%252C9&next=/a/b&child_support_id=#{child_support_id}")
      end

      it "ajoute child_support_id quand l'url n'a pas de paramètres" do
        expect(redirect_location_for('https://1001mots-app1.bubbleapps.io/form'))
          .to eq("https://1001mots-app1.bubbleapps.io/form?child_support_id=#{child_support_id}")
      end
    end

    context "avec une url Typeform" do
      let(:typeform_fields) { "child_support_id=#{child_support_id}&parent_id=#{@redirection_url.parent_id}" }

      it "ajoute les champs cachés en ancre" do
        expect(redirect_location_for('https://wr1q9w7z4ro.typeform.com/to/abc'))
          .to eq("https://wr1q9w7z4ro.typeform.com/to/abc##{typeform_fields}")
      end

      it "complète les champs cachés déjà présents dans l'ancre" do
        expect(redirect_location_for('https://wr1q9w7z4ro.typeform.com/to/abc#source=sms'))
          .to eq("https://wr1q9w7z4ro.typeform.com/to/abc#source=sms&#{typeform_fields}")
      end
    end
  end

end
