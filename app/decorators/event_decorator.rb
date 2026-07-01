class EventDecorator < BaseDecorator

  STATUS_DISPLAY = {
    'En attente' => { css_class: 'pending', css_emoji: 'fas fa-clock' },
    'Livré' => { css_class: 'delivered', css_emoji: 'fas fa-check' },
    'Envoyé' => { css_class: 'sent', css_emoji: 'fas fa-paper-plane' },
    'En cours' => { css_class: 'in-progress', css_emoji: 'fas fa-sync-alt' },
    'Échec' => { css_class: 'failed', css_emoji: 'fas fa-times' },
    'Lu' => { css_class: 'read', css_emoji: 'fas fa-check-double' },
    'Expiré' => { css_class: 'expired', css_emoji: 'fas fa-hourglass-end' }
  }.freeze

  def related_link
    if related = model.related&.decorate
      if related.respond_to?(:admin_link)
        related.admin_link
      else
        auto_link related
      end
    else
      nil
    end
  end

  def related_current_child_group
    decorated_related_current_child&.group
  end

  def related_current_child_group_status
    decorated_related_current_child&.group_status
  end

  def related_current_child_link
    decorated_related_current_child&.admin_link
  end

  def related_current_child_name
    decorated_related_current_child&.name
  end

  def related_name
    decorated_related&.name
  end

  def css_class_name
    "#{model.type.split('::').last.underscore.gsub('_', '-')} #{model.originated_by_app ? 'sent_by_app_text_messages' : 'received_text_messages'}"
  end

  def occurred_at
    h.l model.occurred_at, format: :message
  end

  def display_occurred_at
    label = Event::SPOT_HIT_STATUS[model.spot_hit_status] if model.spot_hit_status
    STATUS_DISPLAY.fetch(label, STATUS_DISPLAY['Expiré'])
  end

  def timeline_occurred_at
    h.l model.occurred_at.to_date, format: :message
  end

  private

  def decorated_related
    @decorated_related ||= model.related&.decorate
  end

  def decorated_related_current_child
    @decorated_related_current_child ||= model.related_current_child&.decorate
  end

end
