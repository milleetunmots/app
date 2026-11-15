require 'rails_helper'

RSpec.describe 'Canal affiché sur la fiche ActiveAdmin d\'un trio', type: :request do
  def with_rcs_single_text(value)
    previous = ENV.fetch('RCS_SINGLE_TEXT_ENABLED', nil)
    value.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = value
    yield
  ensure
    previous.nil? ? ENV.delete('RCS_SINGLE_TEXT_ENABLED') : ENV['RCS_SINGLE_TEXT_ENABLED'] = previous
  end

  def channel_cell(bundle, index)
    get "/admin/media_text_messages_bundles/#{bundle.id}"
    Nokogiri::HTML(response.body).at_css("tr.row-spot_hit_type_#{index} td")
  end

  [
    { flag: 'true', body: 'a' * 300, image: true, link: false, label: 'single' },
    { flag: 'true', body: 'a' * 160, image: false, link: false, label: 'basic' },
    { flag: 'true', body: 'a' * 161, image: false, link: false, label: 'single texte' },
    { flag: 'true', body: 'a' * 158, image: false, link: true, label: 'single texte' },
    { flag: nil, body: 'a' * 161, image: false, link: false, label: 'sms' }
  ].each do |example|
    it "affiche « #{example[:label]} » pour un message de #{example[:body].bytesize} octets " \
       "#{example[:image] ? 'avec' : 'sans'} image, #{example[:link] ? 'avec' : 'sans'} lien, interrupteur #{example[:flag].inspect}" do
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
      bundle = FactoryBot.create(:media_text_messages_bundle, body1: example[:body], body2: nil, body3: nil)
      bundle.update_columns(
        image1_id: example[:image] ? FactoryBot.create(:media_image).id : nil,
        link1_id: example[:link] ? FactoryBot.create(:media_video).id : nil
      )

      label = with_rcs_single_text(example[:flag]) { channel_cell(bundle, 1).text.strip }

      expect(label).to eq(example[:label])
    end
  end

  it "n'affiche aucun canal pour un message vide" do
    sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
    bundle = FactoryBot.create(:media_text_messages_bundle, body1: 'Bonjour !', body2: 'À demain !', body3: nil)

    cell = with_rcs_single_text('true') { channel_cell(bundle, 3) }

    expect(cell.at_css('span.empty')).to be_present
  end
end
