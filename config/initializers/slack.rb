Slack.configure do |config|
  config.token = ENV['SLACK_BOT_USER_OAUTH_TOKEN']
end

# Les alertes sont postées de façon synchrone depuis une requête admin et le gem
# laisse les deux délais à nil : sans bornes, une indisponibilité de Slack ferait
# attendre l'utilisatrice. Les timeouts sont portés par la config du client Web,
# pas par celle du gem (`Slack.configure` n'expose que token et logger).
Slack::Web.configure do |config|
  config.timeout = 5
  config.open_timeout = 2
end
