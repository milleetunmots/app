# WebMock bloque tout HTTP externe : sans ce stub, la moindre alerte Slack
# déclenchée par un test ferait échouer l'exemple. Le gem slack-ruby-client
# envoie toutes ses requêtes en POST.
RSpec.configure do |config|
  config.before do
    stub_request(:post, 'https://slack.com/api/chat.postMessage')
      .to_return(
        status: 200,
        body: { ok: true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
