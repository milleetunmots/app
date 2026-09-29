class Child

  # Détecte les inscriptions arrivées via une URL proposée par une IA générative
  # (ChatGPT et consorts). Ces inscriptions ne sont ni financées ni ciblées : les
  # enfants concernés sont écartés de l'accompagnement.
  #
  # Deux appelants aux données de formes différentes — d'où la signature par
  # mots-clés : `Child::CreateService` travaille sur des attributs non encore
  # persistés, le job quotidien sur des enfants en base.
  class AiRegistrationDetector

    KEYWORDS = %w[chatgpt claude gemini].freeze

    UTM_SOURCE_TAG_PREFIX = 'utm_source='.freeze

    class << self

      def ai_sourced?(tag_list: nil, src_url: nil)
        value = utm_source(tag_list: tag_list, src_url: src_url)
        return false if value.blank?

        downcased = value.downcase
        KEYWORDS.any? { |keyword| downcased.include?(keyword) }
      end

      # Le tag prime : c'est la valeur telle qu'elle a été soumise au formulaire.
      # `src_url` ne sert que de repli pour les parcours où le tag n'a pas été posé.
      def utm_source(tag_list: nil, src_url: nil)
        from_tag_list(tag_list).presence || from_src_url(src_url).presence
      end

      private

      def from_tag_list(tag_list)
        return if tag_list.blank?

        tag = Array(tag_list).map(&:to_s).find { |t| t.downcase.start_with?(UTM_SOURCE_TAG_PREFIX) }
        tag && tag[UTM_SOURCE_TAG_PREFIX.length..]
      end

      # Une `src_url` illisible ne doit pas faire échouer une inscription :
      # en cas de doute, on ne détecte rien.
      def from_src_url(src_url)
        return if src_url.blank?

        query = URI.parse(src_url).query
        return if query.blank?

        URI.decode_www_form(query).to_h['utm_source']
      rescue URI::InvalidURIError, ArgumentError
        nil
      end
    end
  end
end
