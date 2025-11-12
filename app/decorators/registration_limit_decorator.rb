class RegistrationLimitDecorator < BaseDecorator

  def name
    h.link_to model.source.decorate.name, [:admin, model]
  end

  def state
    return 'Archivé' if model.is_archived?

    if model.started? && !model.ended?
      'En cours'
    elsif model.started? && model.ended?
      'Passée'
    else
      'À venir'
    end
  end

  def form_status
    if model.open?
      'Ouvert'
    else
      'Fermé'
    end
  end
end
