class SupportModule::SyncAirtableContentIdsService
  attr_reader :errors

  def initialize
    @errors = []
  end

  def call
    records = Airtables::SupportModuleContent.all(fields: ['titre', 'Age', 'SMS envoyés'])
    if records.empty?
      errors << 'Aucun contenu récupéré depuis Airtable, liens existants conservés.'
      return self
    end

    records_by_id = records.index_by(&:id)
    SupportModule.transaction do
      SupportModule.find_each do |support_module|
        # Une fois le dossier identifié, un renommage ne doit pas casser le lien.
        next if records_by_id.key?(support_module.airtable_content_id)

        matches = Airtables::SupportModuleContent.matches_for(support_module, records)
        if matches.size > 1
          errors << "Plusieurs dossiers Airtable correspondent au module #{support_module.id}, lien inchangé."
          next
        end

        # La liste complète a été récupérée : un ancien dossier absent peut
        # être remplacé par son nouvel équivalent, ou son lien retiré.
        record_id = matches.first&.id
        next if support_module.airtable_content_id == record_id

        support_module.update!(airtable_content_id: record_id)
      end
    end
    self
  rescue Airrecord::Error, Faraday::Error, ActiveRecord::RecordInvalid => e
    errors << "Synchronisation des liens Airtable interrompue : #{e.message}"
    self
  end
end
