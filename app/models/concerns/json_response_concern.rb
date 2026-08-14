# Parsing défensif des réponses JSON des API tierces (client HTTP.rb).
#
# Les API externes ne renvoient pas toujours du JSON : sur les pannes d'infra
# (502/503/504, maintenance, throttling) ou derrière un reverse-proxy, elles
# répondent en texte brut ou en HTML. Un JSON.parse direct lève alors une
# JSON::ParserError qui remonte jusqu'au job appelant et le fait échouer en
# entier — cf. l'incident Spot-Hit du 03/08/2026 sur SelectModuleJob.
module JsonResponseConcern
  extend ActiveSupport::Concern

  # Corps parsé si la réponse est un 2xx contenant du JSON valide, nil sinon.
  # C'est la méthode à utiliser par défaut.
  def parse_json_response(response)
    return nil unless response.status.success?

    parse_json_body(response)
  end

  # Corps parsé quel que soit le statut HTTP, nil si le corps n'est pas du JSON
  # valide. À utiliser quand l'API renvoie un JSON d'erreur exploitable sur les
  # statuts 4xx/5xx (Calendly par exemple).
  def parse_json_body(response)
    JSON.parse(response.body.to_s)
  rescue JSON::ParserError
    nil
  end

  # Sous-ressource attendue dans le corps d'une réponse 2xx (`body['contact']`),
  # ou nil si la réponse est inexploitable ou la clé absente.
  def parse_json_resource(response, key)
    body = parse_json_response(response)
    return nil unless body.is_a?(Hash)

    body[key]
  end

  # Message d'erreur lisible : détail fourni par l'API si on a pu le parser,
  # sinon repli sur le corps brut. Le statut est toujours inclus, sans quoi une
  # panne d'infra est indiscernable d'une erreur métier dans Rollbar.
  def json_error_message(response, body = nil)
    detail = json_error_detail(body)
    detail = response.body.to_s.truncate(500) if detail.blank?

    "HTTP #{response.status} — #{detail}"
  end

  private

  def json_error_detail(body)
    return nil unless body.is_a?(Hash)

    error = body['error']
    return error['message'] if error.is_a?(Hash) && error['message'].present?

    error.presence || body['message'] || body['title'] || body['details'] || body['erreurs']
  end
end
