module ActiveAdmin
  # Le `if:` d'une action groupée ne fait qu'afficher le bouton : ActiveAdmin ne
  # contrôle aucun droit sur l'action `batch_action`, seule la collection est
  # filtrée (`accessible_by(:read)`), et pas du tout quand le bloc refait sa propre
  # requête (`Child.where`, `Group.find`). Une requête forgée lançait donc l'action
  # pour n'importe quel rôle. Ce module évalue le `if:` côté serveur, avant le bloc :
  # un bouton masqué vaut refus, pour toutes les actions groupées, futures comprises.
  module BatchActionGuard
    def batch_action
      authorize_batch_action!(params[:batch_action]) if action_present?
      super
    end

    protected

    # Aussi utilisé par les actions de collection qui prolongent une action groupée
    # (ex. `perform_selecting_available_support_modules`). Le `if:` est évalué dans
    # le contexte de la vue, comme pour l'affichage du bouton : celui de l'action
    # `destroy` par défaut appelle `controller`, qui n'existe que dans la vue.
    def authorize_batch_action!(sym)
      batch_action = active_admin_config.batch_actions.detect { |action| action.sym.to_s == sym.to_s }
      return if batch_action && view_context.instance_exec(&batch_action.display_if_block)

      raise ActiveAdmin::AccessDenied.new(current_active_admin_user, :batch_action, active_admin_config.resource_class)
    end
  end
end
