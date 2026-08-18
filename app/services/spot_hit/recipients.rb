# Normalise les différentes formes de `recipients` acceptées par les services
# d'envoi Spot Hit vers une structure unique indexée par `parent_id`.
#
# Un numéro de téléphone n'identifie pas un parent de façon unique (les deux
# parents d'une famille peuvent partager un numéro, et une famille peut se
# réinscrire des années plus tard avec le même numéro). Les Events doivent donc
# être rattachés à un `parent_id`, et la conversion vers le numéro n'a lieu qu'au
# moment de construire le formulaire envoyé à Spot Hit.
#
# Formes acceptées en entrée (historique) :
#   - Hash{parent_id => {var => valeur}}  (forme privilégiée)
#   - Hash{phone     => {var => valeur}}
#   - Array<Integer> d'ids de parents
#   - Array<String> de numéros
#   - String de numéros séparés par ', '
module SpotHit::Recipients

  # {parent_id => {variable => valeur}}, restreint aux parents non supprimés.
  def recipient_variables
    @recipient_variables ||= begin
      kept = reject_discarded_parents(normalize_recipients(@recipients))
      report_unresolved_phone_numbers(kept)
      kept
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

  # Les formes sans variables (Array/String de numéros ou d'ids) ne portent aucune
  # donnée de personnalisation : l'envoi se fait alors en liste simple.
  def personalized_recipients?
    recipient_variables.values.any?(&:present?)
  end

  # Restreint les destinataires aux numéros autorisés (dev / SPOT_HIT_SAFEGUARD).
  def restrict_recipients_to_safe_numbers!
    safe_numbers = ENV['SAFE_PHONE_NUMBERS'].to_s.split(',').map(&:strip)
    safe_parent_ids = phone_numbers_by_parent_id.select { |_id, phone| safe_numbers.include?(phone) }.keys
    @recipient_variables = recipient_variables.slice(*safe_parent_ids)
    @phone_numbers_by_parent_id = nil
  end

  private

  # Un envoi vers un numéro qui ne correspond à aucun parent actif part quand même
  # chez Spot Hit, mais ne peut pas être tracé dans l'historique : on le signale.
  # Seules les formes indexées par numéro sont concernées, celles indexées par
  # `parent_id` n'ayant rien à résoudre.
  def report_unresolved_phone_numbers(kept_variables)
    return if @requested_phone_numbers.blank?

    resolved = Parent.where(id: kept_variables.keys).pluck(:phone_number).uniq
    (@requested_phone_numbers.uniq - resolved).each do |phone|
      @errors << "Impossible d'enregistrer le #{recipient_history_label} dans l'historique : Parent non trouvé pour le numéro de téléphone #{phone}."
    end
  end

  # Surchargé par les services dont l'historique parle d'autre chose qu'un message.
  def recipient_history_label
    'message'
  end

  # Un parent supprimé (discard) ne doit plus recevoir de message. Le filtrage a
  # lieu ici, au point d'entrée unique : le formulaire Spot Hit et les Events en
  # découlent tous les deux, ils restent donc cohérents entre eux.
  def reject_discarded_parents(normalized)
    return normalized if normalized.empty?

    normalized.slice(*Parent.kept.where(id: normalized.keys).ids)
  end

  def normalize_recipients(recipients)
    case recipients
    when Hash   then normalize_hash_recipients(recipients)
    when Array  then normalize_array_recipients(recipients)
    when String then parent_ids_for_phone_numbers(recipients.split(',')).index_with { {} }
    when Integer then { recipients => {} }
    else {}
    end
  end

  def normalize_hash_recipients(recipients)
    return {} if recipients.empty?
    return recipients.transform_keys(&:to_i) if recipients.keys.first.is_a?(Integer)

    # Forme historique indexée par numéro : un numéro partagé alimente chacun des
    # parents qui le portent, pour que tous aient leur Event.
    recipients.each_with_object({}) do |(phone, variables), normalized|
      parent_ids_for_phone_numbers([phone]).each { |parent_id| normalized[parent_id] = variables }
    end
  end

  def normalize_array_recipients(recipients)
    return {} if recipients.empty?

    if recipients.first.is_a?(Integer)
      recipients.uniq.index_with { {} }
    else
      parent_ids_for_phone_numbers(recipients).index_with { {} }
    end
  end

  def parent_ids_for_phone_numbers(phone_numbers)
    formatted = phone_numbers.map { |phone| Phonelib.parse(phone.to_s.strip).e164.presence || phone.to_s.strip }
    (@requested_phone_numbers ||= []).concat(formatted)
    Parent.where(phone_number: formatted.uniq).ids
  end
end
