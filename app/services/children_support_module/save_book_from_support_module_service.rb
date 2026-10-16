class ChildrenSupportModule

  class SaveBookFromSupportModuleService

    # Support module has books associated, but these can change over time
    # So we save the book associated to a chosen module on the corresponding CSM before we send them.
    # Books that won't ship (suspected address, interrupted support) are saved too and marked
    # « Non envoyé », so the follow-up page shows them.

    def initialize(group_id:)
      @group_id = group_id
    end

    def call
      # get not_programmed + with_support_module CSM for the group (only parent1 choices)
      chosen_modules = ChildrenSupportModule.chosen_modules_for_group(@group_id, include_unshippable: true)
      chosen_modules = chosen_modules.select { |csm| csm.child.group_status.in?(ChildrenSupportModule::BOOK_TRACKED_GROUP_STATUSES) }
      chosen_modules = chosen_modules.uniq { |csm| [csm.child_id, csm.parent_id] }
      return if chosen_modules.empty?

      shippable_modules, unshippable_modules = chosen_modules.partition(&:shippable?)
      # les CSM des enfants inactifs ne sont jamais programmés et repassent ici à chaque module :
      # seuls ceux qui n'ont pas encore de livre sont traités, pour ne pas redater le « Non envoyé »
      not_sent_ids = unshippable_modules.select { |csm| csm.book_id.nil? }.map(&:id)

      ActiveRecord::Base.transaction do
        save_books(shippable_modules.map(&:id) + not_sent_ids)
        mark_as_not_sent(not_sent_ids)
      end
    end

    private

    def save_books(ids)
      return if ids.empty?

      # SQL query because AR update_call can't handle joins
      ActiveRecord::Base.connection.execute(<<-SQL.squish)
        UPDATE children_support_modules
        SET book_id = support_modules.book_id
        FROM support_modules
        WHERE children_support_modules.support_module_id = support_modules.id
        AND children_support_modules.id IN (#{ids.join(',')});
      SQL
    end

    # update_all saute volontairement le callback qui marque l'adresse suspecte lors d'une pose
    # manuelle : une famille interrompue a une adresse correcte, la marquer serait un faux positif
    def mark_as_not_sent(ids)
      ChildrenSupportModule.where(id: ids, book_condition: nil)
                           .update_all(book_condition: ChildrenSupportModule::NOT_SENT, book_condition_changed_at: Time.zone.now)
    end
  end
end
