class ProgramAutomaticMessageService < ProgramMessageService

  def initialize(*args, automatic_message_key:, **options)
    super(*args, **options)
    @replay_params[:automatic_message_key] = automatic_message_key
    # Valeur par défaut : la clé s'applique à chaque parent destinataire.
    @event_params = Hash.new({ automatic_message_key: automatic_message_key }.freeze)
  end
end
