require 'rails_helper'

RSpec.describe 'Programmation des envois Spot Hit' do
  let(:parent) { FactoryBot.create(:parent) }
  let(:now) { Time.zone.local(2026, 9, 14, 14, 30, 0) }

  around do |example|
    travel_to(now) { example.run }
  end

  [:sms, :rcs_basic, :rcs_single].each do |channel|
    context channel.to_s do
      let(:url) { "https://www.spot-hit.fr/api/envoyer/#{channel == :sms ? 'sms' : 'rcs'}" }

      def build_service(timestamp)
        if channel == :sms
          SpotHit::SendSmsService.new([parent.id], timestamp, 'Bonjour !')
        else
          SpotHit::SendRcsService.new(
            recipients: [parent.id], planned_timestamp: timestamp,
            fallback_message: 'Bonjour !', basic: channel == :rcs_basic,
            media_id: channel == :rcs_single ? 42 : nil
          )
        end
      end

      let(:channel) { channel }

      [0, -10.minutes].each do |offset|
        it "demande un envoi immédiat sans date pour une heure échue (#{offset.to_i}s)" do
          service = build_service((now + offset).to_i).call

          expect(service.errors).to be_empty
          expect(service).to be_sent
          expect(WebMock).to have_requested(:post, url).with { |request| !URI.decode_www_form(request.body).to_h.key?('date') }
        end
      end

      it 'conserve une programmation future' do
        planned_at = now + 1.hour
        build_service(planned_at.to_i).call

        expected_date = channel == :sms ? planned_at.to_i.to_s : '2026-09-14 15:30:00'
        expect(WebMock).to have_requested(:post, url).with(body: hash_including('date' => expected_date))
      end

      it "réévalue la date au moment de l'envoi, après l'initialisation" do
        service = build_service((now + 1.minute).to_i)
        travel 2.minutes
        service.call

        expect(WebMock).to have_requested(:post, url).with { |request| !URI.decode_www_form(request.body).to_h.key?('date') }
      end
    end
  end

  it 'formate les RCS futurs en heure de Paris même si le contexte utilise UTC' do
    parent_id = parent.id
    Time.use_zone('UTC') do
      SpotHit::SendRcsService.new(
        recipients: [parent_id], planned_timestamp: (now + 1.hour).to_i,
        basic: true, fallback_message: 'Bonjour !'
      ).call
    end

    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
      .with(body: hash_including('date' => '2026-09-14 15:30:00'))
  end
end
