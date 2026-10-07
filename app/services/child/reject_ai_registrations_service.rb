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
        next unless child.ai_sourced_registration?

        reject(child)
      end
      if @rejected_children_ids.any?
        Rollbar.info(
          "#{self.class} done",
          rejected_children_count: @rejected_children_ids.size,
          rejected_children_ids: @rejected_children_ids
        )
      end
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

    def reject(child)
      # `remove_group` (callback sur Child) détache la cohorte tout seul.
      @rejected_children_ids << child.id if child.update(group_status: 'not_supported')
    end
  end
end
