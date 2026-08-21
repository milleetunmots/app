class SeedHardcodedUrlAllowedPatterns < ActiveRecord::Migration[7.0]

  # Domaines déjà utilisés en production, qui seraient refusés dès l'activation
  # de URL_FILTER_BLOCKING_ENABLED. Deux origines :
  #
  # 1. des liens en dur dans des messages sortants automatiques (non relançables
  #    depuis l'admin, faute de replay_params) :
  #    - 1001mots.org : adresse pmi@1001mots.org dans
  #      ChildSupport::CallerStopSupportService (un email est vu comme un lien)
  #    - youtube.com : playlist proposée par le même service
  #    - instagram.com : ENV['INSTAGRAM_LINK'] dans Child::CreateService et
  #      Group::StopSupportService
  #
  # 2. les domaines des médias utilisables en redirection (cf. rake
  #    url_filter:audit_media). Volontairement enregistrés au sous-domaine près
  #    quand celui-ci identifie le compte 1001mots : autoriser bubbleapps.io,
  #    notion.site ou typeform.com en entier reviendrait à autoriser l'espace de
  #    n'importe quel autre client de ces plateformes.
  #
  # Les raccourcisseurs d'url présents en base (vu.fr, urlz.fr, bit.ly) sont
  # volontairement exclus : ils redirigent vers une destination arbitraire et
  # non contrôlable, ce qui viderait le filtre de son sens.
  DOMAINS = %w[
    1001mots.org
    youtube.com
    instagram.com
    1001mots-app1.bubbleapps.io
    magical-bull-428.notion.site
    wr1q9w7z4ro.typeform.com
    youtu.be
    forms.gle
    docs.google.com
    facebook.com
    questionnaires.moselle.fr
    notion.so
    airtable.com
  ].freeze

  def up
    values = DOMAINS.map { |domain| "('url', 'domain', #{connection.quote(domain)}, NOW(), NOW())" }.join(', ')

    execute <<~SQL.squish
      INSERT INTO allowed_patterns (kind, match_type, value, created_at, updated_at)
      VALUES #{values}
      ON CONFLICT (kind, match_type, value) DO NOTHING
    SQL
  end

  def down
    values = DOMAINS.map { |domain| connection.quote(domain) }.join(', ')

    execute <<~SQL.squish
      DELETE FROM allowed_patterns
      WHERE kind = 'url' AND match_type = 'domain' AND value IN (#{values})
    SQL
  end
end
