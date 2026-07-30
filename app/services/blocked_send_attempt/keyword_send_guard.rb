# Détection de termes interdits (BlockedPattern) dans les messages sortants.
# Miroir de UrlSendGuard : surveillance par défaut, blocage via
# KEYWORD_FILTER_BLOCKING_ENABLED.
class BlockedSendAttempt::KeywordSendGuard < BlockedSendAttempt::BaseSendGuard

  def self.blocking_enabled?
    ENV['KEYWORD_FILTER_BLOCKING_ENABLED'].present?
  end

  def self.kind
    'keyword'
  end

  def detected_values
    blocked_values
  end

  def blocked_values
    @blocked_values ||=
      begin
        normalized = BlockedPattern.normalize(scannable_text)
        if normalized.blank?
          []
        else
          BlockedPattern.where(kind: 'keyword')
                        .select { |pattern| pattern.matches_normalized?(normalized) }
                        .map(&:value)
                        .uniq
        end
      end
  end
end
