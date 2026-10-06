class Child

  # Rattrape les inscriptions issues d'une IA générative qui ont échappé au
  # filtre posé à l'inscription (imports, reprises de données, stock antérieur à
  # la mise en place du filtre).
  #
  # Garde-fou métier : on n'écarte jamais un enfant dont l'accompagnement a
  # démarré. La programmation de la cohorte est le marqueur retenu.
  class RejectAiRegistrationsService

    attr_reader :rejected_children_ids

    def initialize
      @rejected_children_ids = []
    end

    def call
      eligible_children.find_each do |child|
        utm_source = Child::AiRegistrationDetector.utm_source(tag_list: child.tag_list, src_url: child.src_url)
        next unless Child::AiRegistrationDetector.ai_sourced?(tag_list: child.tag_list, src_url: child.src_url)

        reject(child, utm_source)
      end
      Rails.logger.info("#{self.class}: #{@rejected_children_ids.size} enfant(s) écarté(s)")
      self
    end

    private

    # Sans cohorte, ou dans une cohorte pas encore programmée. `find_each` car le
    # premier passage traite un stock dont le volume est inconnu. `IS DISTINCT
    # FROM` garde les statuts vides (données anciennes), que `where.not` exclurait.
    def eligible_children
      Child.kept
           .where('children.group_status IS DISTINCT FROM ?', 'not_supported')
           .left_joins(:group)
           .where('children.group_id IS NULL OR groups.is_programmed = ?', false)
    end

    def reject(child, utm_source)
      # `remove_group` (callback sur Child) détache la cohorte tout seul.
      if child.update(group_status: 'not_supported')
        @rejected_children_ids << child.id
        Rails.logger.info("#{self.class}: enfant #{child.id} écarté (utm_source=#{utm_source})")
      else
        Rails.logger.error("#{self.class}: échec sur l'enfant #{child.id} : #{child.errors.full_messages.join(', ')}")
      end
    end
  end
end
