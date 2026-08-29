# Normalise les différentes formes de `recipients` acceptées par les services
# d'envoi Spot Hit vers une structure unique indexée par `parent_id`.
#
# Un numéro de téléphone n'identifie pas un parent de façon unique (les deux
# parents d'une famille peuvent partager un numéro, et une famille peut se
# réinscrire des années plus tard avec le même numéro). Les Events doivent donc
# être rattachés à un `parent_id`, et la conversion vers le numéro n'a lieu qu'au
# moment de construire le formulaire envoyé à Spot Hit.
#
# Formes acceptées en entrée :
#   - Hash{parent_id => {var => valeur}}
#   - Array<Integer> d'ids de parents
#   - Integer pour un parent unique
module SpotHit::Recipients

  # {parent_id => {variable => valeur}}, restreint aux parents non supprimés.
  def recipient_variables
    @recipient_variables ||= begin
      normalized = normalize_recipients(@recipients)
      kept = reject_discarded_parents(normalized)
      report_unresolved_parent_ids(normalized, kept)
      keep_preferred_parent_per_phone_number(kept)
    end
  end

  # {parent_id => phone_number}
  def phone_numbers_by_parent_id
    @phone_numbers_by_parent_id ||= Parent.where(id: recipient_variables.keys).pluck(:id, :phone_number).to_h
  end

  # Spot Hit dédoublonne par numéro : un numéro partagé ne reçoit qu'un message.
  def recipient_phone_numbers
    phone_numbers_by_parent_id.values.compact.uniq
  end

  # Les vraies URLs envoyées sont souvent dans les variables destinataires
  # ({URL}, {CALLx_CALENDLY_LINK}…), le message ne contenant que des placeholders :
  # les filtres d'URL et de mots-clés doivent donc aussi inspecter ces valeurs.
  # La normalisation garantit déjà un Hash ; le test de type reste une ceinture de
  # sécurité, ce filtre étant un contrôle de sécurité qui ne doit jamais planter.
  def recipient_variable_values
    recipient_variables.values.flat_map { |variables| variables.respond_to?(:values) ? variables.values : [] }
  end

  # Une forme Hash exprime une intention de personnalisation, même si toutes les
  # variables se révèlent vides (message contenant un `{TOKEN}` non reconnu) : on
  # reste alors en mode `datas`, que Spot Hit rejette, plutôt que de basculer en
  # liste simple et de diffuser le message avec ses placeholders non substitués.
  # Les formes Array/String ne portent aucune donnée de personnalisation.
  def personalized_recipients?
    recipient_variables # force la normalisation
    @personalized_recipients
  end

  # Restreint les destinataires aux numéros autorisés (dev / SPOT_HIT_SAFEGUARD).
  def restrict_recipients_to_safe_numbers!
    safe_numbers = ENV['SAFE_PHONE_NUMBERS'].to_s.split(',').map(&:strip)
    safe_parent_ids = phone_numbers_by_parent_id.select { |_id, phone| safe_numbers.include?(phone) }.keys
    @recipient_variables = recipient_variables.slice(*safe_parent_ids)
    @phone_numbers_by_parent_id = nil
  end

  def recipients_available?
    return true if recipient_variables.any?

    @errors << 'Aucun parent actif à contacter.' if @errors.empty?
    false
  end

  private

  def report_unresolved_parent_ids(normalized, kept)
    (normalized.keys - kept.keys).each do |parent_id|
      @errors << "Message non envoyé : aucun parent actif ne correspond à l'identifiant #{parent_id}."
    end
  end

  # Spot Hit n'accepte qu'une personnalisation par numéro. Si les IDs sont les
  # parent1 et parent2 d'un même enfant, parent1 est prioritaire. Dans les autres
  # cas (notamment une réinscription), on conserve la fiche la plus récente.
  # Le formulaire et l'Event restent ainsi strictement cohérents.
  def keep_preferred_parent_per_phone_number(variables)
    return variables if variables.one?

    parents = Parent.where(id: variables.keys).order(:created_at, :id).pluck(:id, :phone_number)
    phone_number_by_parent_id = parents.to_h
    parent_pairs = Child.kept
                        .where(parent1_id: variables.keys, parent2_id: variables.keys)
                        .pluck(:parent1_id, :parent2_id)
    priority_parent1_ids = parent_pairs.filter_map do |parent1_id, parent2_id|
      parent1_id if phone_number_by_parent_id[parent1_id] == phone_number_by_parent_id[parent2_id]
    end.index_with(true)

    preferred_parent_ids = parents.group_by(&:second).values.map do |parents_with_same_phone|
      parent1s = parents_with_same_phone.select { |parent_id, _phone| priority_parent1_ids.key?(parent_id) }
      (parent1s.presence || parents_with_same_phone).last.first
    end
    variables.slice(*preferred_parent_ids)
  end

  # Un parent supprimé (discard) ne doit plus recevoir de message. Le filtrage a
  # lieu ici, au point d'entrée unique : le formulaire Spot Hit et les Events en
  # découlent tous les deux, ils restent donc cohérents entre eux.
  def reject_discarded_parents(normalized)
    return normalized if normalized.empty?

    normalized.slice(*Parent.kept.where(id: normalized.keys).ids)
  end

  def normalize_recipients(recipients)
    @personalized_recipients = recipients.is_a?(Hash) && recipients.any?
    case recipients
    when Hash   then normalize_hash_recipients(recipients)
    when Array  then normalize_array_recipients(recipients)
    when Integer then { recipients => {} }
    else invalid_recipient_format
    end
  end

  # La valeur est toujours ramenée à un Hash : tout l'aval (construction du
  # formulaire, filtres d'URL) itère dessus sans avoir à se garder du nil.
  def normalize_hash_recipients(recipients)
    return {} if recipients.empty?
    return invalid_recipient_format unless recipients.keys.all? { |parent_id| parent_id.is_a?(Integer) }

    recipients.to_h { |parent_id, variables| [parent_id, variables || {}] }
  end

  def normalize_array_recipients(recipients)
    return {} if recipients.empty?
    return invalid_recipient_format unless recipients.all? { |parent_id| parent_id.is_a?(Integer) }

    recipients.uniq.index_with { {} }
  end

  def invalid_recipient_format
    @errors << 'Format de destinataires invalide : utilisez uniquement des identifiants de parents.'
    {}
  end
end
