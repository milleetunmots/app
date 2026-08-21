namespace :url_filter do
  desc "Liste les médias utilisables en redirection dont l'url serait refusée (à passer avant d'activer URL_FILTER_BLOCKING_ENABLED)"
  task audit_media: :environment do
    # L'url cible d'un redirection_target n'apparaît jamais dans le message
    # envoyé (le parent reçoit le short link de l'app) : le guard d'envoi ne
    # peut donc pas la voir, et la validation Medium est inactive tant que le
    # flag est absent. Sans cet audit, on ne découvre les médias non conformes
    # qu'au moment de l'activation.
    refused = Medium.refused_by_url_filter

    puts "#{refused.count} média(s) seraient refusé(s) sur #{Medium.for_redirections.kept.count}"
    refused.each { |medium| puts "  ##{medium.id} #{medium.type} — #{medium.name} — #{medium.url}" }
  end
end
