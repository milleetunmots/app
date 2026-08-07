# Outil offline d'aide au choix des termes : combien de messages sortants déjà
# envoyés auraient matché ce candidat ? Beaucoup de matchs = mauvais candidat
# (faux positifs). Aucun stockage, aucun scoring persistant.
class BlockedPattern::AuditService

  EXCERPT_RADIUS = 40
  PHONE_MASK_REGEX = /\+?(?:\d[\s.-]?){6,}\d/

  attr_reader :matches_count, :excerpts

  def initialize(term, excerpts_limit: 5)
    @term = term
    @excerpts_limit = excerpts_limit
    @matches_count = 0
    @excerpts = []
  end

  def call
    regex = BlockedPattern.regex_for(BlockedPattern.normalize(@term))
    Events::TextMessage.where(originated_by_app: true).find_each do |event|
      normalized_body = BlockedPattern.normalize(event.body)
      match = regex.match(normalized_body)
      next unless match

      @matches_count += 1
      @excerpts << anonymized_excerpt(normalized_body, match) if @excerpts.size < @excerpts_limit
    end
    self
  end

  private

  def anonymized_excerpt(normalized_body, match)
    from = [match.begin(0) - EXCERPT_RADIUS, 0].max
    to = match.end(0) + EXCERPT_RADIUS
    normalized_body[from...to].gsub(PHONE_MASK_REGEX, '[num]')
  end
end
