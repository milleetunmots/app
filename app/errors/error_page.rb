# Page d'erreur unique, aux couleurs de la charte, pour toute réponse d'erreur
# (404, 422, 500, 400, 406, 429…). Application Rack autonome : elle ne dépend ni de la
# base, ni des vues, ni de la session, pour rester affichable quand le reste est en panne.
#
# - Rails l'appelle pour les exceptions (config.exceptions_app, cf. config/application.rb) ;
#   ShowExceptions place le code HTTP dans le chemin ("/404").
# - Rack::Attack la réutilise pour ses 429 (config/initializers/rack_attack.rb), qui
#   sortent avant Rails.
# - Dans un contrôleur, pour une page introuvable : `not_found` (ApplicationController),
#   jamais `head :not_found`, qui rend une page blanche.
module ErrorPage
  TEMPLATE = Rails.root.join('app/errors/error_page.html')

  NOT_FOUND = [
    "Cette page n'existe pas ou n'existe plus",
    "Cette page est partie jouer à cache-cache, et elle est douée. Le lien que vous avez suivi n'est peut-être plus valide : toutes nos excuses."
  ].freeze
  REJECTED = [
    "La demande n'a pas pu aboutir",
    "Oups, votre demande s'est perdue en route. Nous sommes désolés : merci de réessayer dans quelques instants."
  ].freeze
  TOO_MANY = [
    'Trop de tentatives',
    'Doucement, on respire ! Patientez quelques instants avant de réessayer.'
  ].freeze
  FAILURE = [
    'Une erreur est survenue',
    "Notre page fait une sieste imprévue. Nous sommes désolés : réessayez dans quelques minutes, elle devrait être réveillée."
  ].freeze

  TEXTS = { 400 => REJECTED, 404 => NOT_FOUND, 422 => REJECTED, 429 => TOO_MANY }.freeze

  module_function

  # Application Rack appelée par Rails pour une exception
  def call(env)
    status = env['PATH_INFO'].to_s[%r{\A/(\d{3})\z}, 1].to_i
    response(status.zero? ? 500 : status)
  end

  # Triplet Rack pour un code HTTP, avec d'éventuels en-têtes en plus (ex. Retry-After)
  def response(status, headers = {})
    title, message = TEXTS.fetch(status, FAILURE)
    body = TEMPLATE.read
                   .gsub('{{status}}', status.to_s)
                   .gsub('{{title}}', title)
                   .gsub('{{message}}', message)
    [
      status,
      { 'Content-Type' => 'text/html; charset=utf-8', 'Content-Length' => body.bytesize.to_s }.merge(headers),
      [body]
    ]
  end
end
