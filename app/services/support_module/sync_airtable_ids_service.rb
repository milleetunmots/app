class SupportModule::SyncAirtableIdsService

  attr_reader :errors

  def initialize
    @errors = []
  end

  def call
    airtable_modules = fetch_airtable_modules
    return self if airtable_modules.nil?

    if airtable_modules.empty? && SupportModule.unscoped.where.not(airtable_id: nil).exists?
      @errors << 'Aucun module récupéré depuis Airtable, synchronisation ignorée par sécurité.'
      return self
    end

    synced_record_ids = airtable_modules.filter_map { |airtable_module| sync(airtable_module) }
    clean_missing_records(synced_record_ids)
    self
  end

  private

  def fetch_airtable_modules
    Airtables::Module.all
  rescue Airrecord::Error => e
    @errors << "Erreur Airtable lors de la récupération des modules : #{e.message}"
    nil
  end

  # Retourne l'id d'enregistrement Airtable quand le module a été apparié.
  def sync(airtable_module)
    support_module = airtable_module.support_module
    if support_module.nil?
      @errors << "#{airtable_module.title} #{airtable_module.ages} introuvable"
      return nil
    end

    # SupportModule est versionné (paper_trail) : on n'écrit que si nécessaire
    return airtable_module.id if support_module.airtable_id == airtable_module.id

    release_record_id(airtable_module.id, support_module.id)
    support_module.update!(airtable_id: airtable_module.id)
    airtable_module.id
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    @errors << "Erreur lors de la sauvegarde du module #{support_module&.name} : #{e.message}"
    nil
  end

  # L'index est unique : un enregistrement Airtable déjà rattaché à un autre
  # module (typiquement un module archivé, hors du default_scope) doit être
  # libéré avant d'être réaffecté
  def release_record_id(record_id, support_module_id)
    SupportModule.unscoped
                 .where(airtable_id: record_id)
                 .where.not(id: support_module_id)
                 .update_all(airtable_id: nil)
  end

  # Un module retiré d'Airtable ne doit plus pointer vers un enregistrement
  # qui n'existe pas. Aucun appariement du tout n'est traité comme suspect :
  # on préfère laisser les liens en place plutôt que tous les effacer.
  def clean_missing_records(synced_record_ids)
    return if synced_record_ids.empty?

    SupportModule.unscoped
                 .where.not(airtable_id: nil)
                 .where.not(airtable_id: synced_record_ids)
                 .update_all(airtable_id: nil)
  end
end
