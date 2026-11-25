class ProgramAutomaticMessageService < ProgramMessageService

  # all_recipients : les messages d'inscription partaient sans filtre de statut ni de validité ; ils gardent ces destinataires.
  def initialize(*args, automatic_message_key:, recipient_variables: {}, all_recipients: false, **options)
    super(*args, **options)
    @replay_params[:automatic_message_key] = automatic_message_key
    @replay_params[:recipient_variables] = recipient_variables if recipient_variables.present?
    @replay_params[:all_recipients] = true if all_recipients
    @recipient_variables = recipient_variables.to_h.transform_keys(&:to_i)
    @all_recipients = all_recipients
    @group_status = Child::GROUP_STATUS if all_recipients
    # Valeur par défaut : la clé s'applique à chaque parent destinataire.
    @event_params = Hash.new({ automatic_message_key: automatic_message_key }.freeze)
  end

  # Les valeurs fournies pour une famille remplacent celles que ProgramMessageService calcule.
  def format_data_for_spot_hit(*)
    super
    return unless @recipient_data.is_a?(Hash)

    @recipient_data.each { |parent_id, data| data.merge!(@recipient_variables.fetch(parent_id, {}).slice(*@variables)) }
  end

  private

  def verify_parent_and_children_validity
    super unless @all_recipients
  end
end
