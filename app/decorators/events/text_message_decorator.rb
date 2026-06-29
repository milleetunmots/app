class Events::TextMessageDecorator < EventDecorator

  # Libellés et icônes affichés sous chaque bulle dans la vue "chat" de
  # l'historique. La clé correspond à Event::SPOT_HIT_STATUS.
  CHAT_STATUS = {
    'En attente' => { label: 'Programmé', css_class: 'scheduled', icon: 'fas fa-clock' },
    'Livré' => { label: 'Reçu', css_class: 'delivered', icon: 'fas fa-check-double' },
    'Envoyé' => { label: 'Envoyé', css_class: 'sent', icon: 'fas fa-paper-plane' },
    'En cours' => { label: 'En cours', css_class: 'in-progress', icon: 'fas fa-sync-alt' },
    'Échec' => { label: 'Non reçu', css_class: 'failed', icon: 'fas fa-times' },
    'Lu' => { label: 'Ouvert', css_class: 'read', icon: 'fas fa-check-double' },
    'Expiré' => { label: 'Expiré', css_class: 'expired', icon: 'fas fa-hourglass-end' }
  }.freeze

  def name
    [
      related_name,
      occurred_at
    ].join(' - ')
  end

  def timeline_description
    if originated_by_app
      'Envoyé par <span style="color: #e84e0f;">1001mots</span>.'.html_safe
    else
      [
        related_link,
        'a répondu par SMS'
      ].join(' ').html_safe
    end
  end

  # Type de bulle pour l'historique "chat" :
  # - incoming  : message reçu du parent (gris, aligné à gauche)
  # - scheduled : message programmé pas encore envoyé (gris, aligné à droite)
  # - rcs       : envoyé via le canal RCS (bleu)
  # - sms       : envoyé via SMS, y compris fallback RCS->SMS (vert)
  def chat_bubble_class
    return 'incoming' unless originated_by_app
    return 'scheduled' if model.spot_hit_status.to_i.zero?

    rcs_channel? ? 'rcs' : 'sms'
  end

  def rcs_channel?
    model.spot_hit_rcs_id.present? && !model.is_fallback
  end

  def chat_status
    label = Event::SPOT_HIT_STATUS[model.spot_hit_status.to_i]
    CHAT_STATUS.fetch(label, CHAT_STATUS['Expiré'])
  end

  def chat_sender
    "envoyé par #{related_name}"
  end

  def spot_hit_status_value
    return unless spot_hit_status.present?

    Event::SPOT_HIT_STATUS[spot_hit_status]
  end

  def truncated_body
    # model.body.truncate 30,
    #                     separator: /\s/,
    #                     omission: ' (…)'
    model.body
  end

end
