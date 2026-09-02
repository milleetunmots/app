# Poste un message dans un canal Slack via `chat.postMessage`. Le module `Slack`
# est celui du gem slack-ruby-client, Zeitwerk le réutilise tel quel.
#
# Aucune erreur ne remonte : une alerte Slack est toujours accessoire au geste
# métier qui la déclenche, elle ne doit jamais le faire échouer. Les échecs sont
# exposés dans `errors`, à charge de l'appelant de les tracer (cf.
# Aircall::CreateCallService).
module Slack
  class PostMessageService

    attr_reader :errors

    # `text` est interprété en mrkdwn (`*gras*`, `_italique_`, `<url|libellé>`).
    #
    # `icon_emoji` (`':rotating_light:'`) et `username` remplacent la photo de
    # profil et le nom affiché du bot pour ce message. Slack exige le scope
    # `chat:write.customize` en plus de `chat:write` : sans lui, les deux sont
    # simplement ignorés et le message part sous l'identité par défaut de l'app.
    def initialize(channel:, text:, icon_emoji: nil, username: nil)
      @errors = []
      @channel = channel
      @text = text
      @icon_emoji = icon_emoji
      @username = username
    end

    def call
      client.chat_postMessage(
        { channel: @channel, text: @text, icon_emoji: @icon_emoji, username: @username }.compact
      )
      self
    rescue StandardError => e
      # Les erreurs du gem descendent toutes de `Faraday::Error` (SlackError,
      # TooManyRequestsError, TimeoutError…), mais un appel incomplet lève un
      # ArgumentError avant même la requête HTTP.
      @errors << "Slack chat.postMessage vers #{@channel} : #{e.message}"
      self
    end

    private

    def client
      @client ||= Slack::Web::Client.new
    end
  end
end
