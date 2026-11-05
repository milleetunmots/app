class AddCalendlyOneOffEventTypeUrisToParents < ActiveRecord::Migration[7.0]

  def change
    # { "<uri du type d'événement one-off>" => session d'appel } : historique conservé
    # pour retrouver le parent quand le lien réservé a perdu ses paramètres utm.
    add_column :parents, :calendly_one_off_event_type_uris, :jsonb, default: {}
  end
end
