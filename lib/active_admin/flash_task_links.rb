module ActiveAdmin
  # Le message d'un envoi bloqué renvoie vers la tâche de suivi. Un flash
  # traverse le cookie de session et revient en String simple, qu'ActiveAdmin
  # échappe : on remplace les seules URLs de tâches de l'application par un lien
  # « Voir la tâche », le reste du message restant échappé.
  module FlashTaskLinks
    LINK_LABEL = 'Voir la tâche'.freeze

    def self.render(message)
      return message if message.html_safe?

      pattern = task_url_pattern
      return ERB::Util.html_escape(message.to_s) if pattern.nil?

      helpers = ActionController::Base.helpers
      parts = message.to_s.split(/(#{pattern})/).map do |part|
        part.match?(/\A#{pattern}\z/) ? helpers.link_to(LINK_LABEL, part, class: 'flash-task-link') : part
      end
      helpers.safe_join(parts)
    end

    # nil quand l'hôte n'est pas configuré : les helpers `_url` lèvent alors, et
    # le flash doit s'afficher quand même.
    def self.task_url_pattern
      %r{#{Regexp.escape(Rails.application.routes.url_helpers.admin_tasks_url)}/\d+\b}
    rescue StandardError
      nil
    end

    def build_flash_messages
      div class: 'flashes' do
        flash_messages.each do |type, messages|
          [*messages].each do |message|
            div FlashTaskLinks.render(message), class: "flash flash_#{type}"
          end
        end
      end
    end
  end
end
