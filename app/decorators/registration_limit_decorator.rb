class RegistrationLimitDecorator < BaseDecorator

  def name
    h.link_to model.source.decorate.name, [:admin, model]
  end
end
