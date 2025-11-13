class RegistrationLimitDecorator < BaseDecorator

  def name
    h.link_to model.source.decorate.name, [:admin, model]
  end

  def registration_link
    "#{model.registration_link.label} (#{model.registration_link.url})"
  end

  def state
    return 'Archivé' if model.is_archived?
    return 'À venir' unless model.started?

    model.ended? ? 'Passée' : 'En cours'
  end

  def form_status
    return 'Ouvert' if !model.started? || model.is_archived? || model.ended?

    if model.open?
      'Ouvert'
    else
      'Fermé'
    end
  end

  def start_date
    model.start_date.strftime('%d/%m/%Y')
  end

  def end_date
    model.end_date&.strftime('%d/%m/%Y')
  end
end
