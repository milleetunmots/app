class ChildrenSupportModule

  class SaveBookFromSupportModuleService

    # Support module has books associated, but these can change over time
    # So we save the book associated to a chosen module on the corresponding CSM before we send them.
    # Books that won't ship (suspected address, interrupted support) are saved too and marked
    # « Non envoyé », so the follow-up page shows them.
    # A saved book is never changed afterwards, even by a rerun working on an outdated list.

    # une condition vidée depuis la fiche vaut '' et non NULL
    BLANK_CONDITION = "COALESCE(children_support_modules.book_condition, '') = ''".freeze

    def initialize(group_ids:, children_support_modules: nil)
      @group_ids = group_ids
      @children_support_modules = children_support_modules
    end

    def call
      # get not_programmed + with_support_module CSM for the groups (only parent1 choices),
      # unless the caller gives the list it already used (logistic export)
      chosen_modules = @children_support_modules || ChildrenSupportModule.chosen_modules_for_group(@group_ids, include_unshippable: true)
      chosen_modules = chosen_modules.select { |csm| csm.child.group_status.in?(ChildrenSupportModule::BOOK_TRACKED_GROUP_STATUSES) }
      chosen_modules = chosen_modules.uniq { |csm| [csm.child_id, csm.parent_id] }
      # les CSM des enfants inactifs ne sont jamais programmés et repassent ici à chaque module :
      # seuls ceux qui n'ont pas encore de livre sont traités (csm[:book_id] : book_id est délégué au livre)
      chosen_modules = chosen_modules.select { |csm| csm[:book_id].nil? }
      return if chosen_modules.empty?

      shippable_modules, unshippable_modules = chosen_modules.partition(&:shippable?)

      ActiveRecord::Base.transaction do
        save_books(shippable_modules.map(&:id))
        save_books(unshippable_modules.map(&:id), not_sent: true)
      end
    end

    private

    # SQL query because AR update_call can't handle joins.
    # book_id IS NULL : la liste a pu être lue avant qu'une autre exécution n'enregistre le livre.
    # Le marquage « Non envoyé » saute volontairement le callback qui marque l'adresse suspecte
    # lors d'une pose manuelle : une famille interrompue a une adresse correcte.
    def save_books(ids, not_sent: false)
      return if ids.empty?

      assignments = ['book_id = support_modules.book_id']
      if not_sent
        assignments << "book_condition = CASE WHEN #{BLANK_CONDITION} THEN '#{ChildrenSupportModule::NOT_SENT}' ELSE children_support_modules.book_condition END"
        assignments << "book_condition_changed_at = CASE WHEN #{BLANK_CONDITION} THEN :now ELSE children_support_modules.book_condition_changed_at END"
      end

      ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array([<<-SQL.squish, { ids: ids, now: Time.zone.now }]))
        UPDATE children_support_modules
        SET #{assignments.join(', ')}
        FROM support_modules
        WHERE children_support_modules.support_module_id = support_modules.id
        AND children_support_modules.id IN (:ids)
        AND children_support_modules.book_id IS NULL
        AND support_modules.book_id IS NOT NULL;
      SQL
    end
  end
end
