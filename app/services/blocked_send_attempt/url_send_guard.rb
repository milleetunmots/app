class BlockedSendAttempt::UrlSendGuard

  URL_REGEX = %r{https?://\S+}i

  def self.blocking_enabled?
    ENV['URL_FILTER_BLOCKING_ENABLED'].present?
  end

  def initialize(text, provider:, replay_params: {}, blocked_send_attempt_id: nil)
    @text = text
    @provider = provider
    @replay_params = replay_params
    @blocked_send_attempt_id = blocked_send_attempt_id
  end

  def blocked?
    blocked_urls.any?
  end

  # Tant que URL_FILTER_BLOCKING_ENABLED n'est pas activé, on se contente de tracer
  # la tentative (via register!) sans empêcher l'envoi réel.
  def block_send?
    blocked? && self.class.blocking_enabled?
  end

  def blocked_urls
    @blocked_urls ||= @text.to_s.scan(URL_REGEX).uniq.reject { |url| AllowedPattern.url_allowed?(url) }
  end

  def register!
    return if @blocked_send_attempt_id.present?

    BlockedSendAttempt.create!(
      provider: @provider,
      kind: 'url',
      detected_values: blocked_urls,
      message_body: @text,
      replay_params: @replay_params,
      status: block_send? ? 'pending' : 'not_blocked'
    )
  end
end
