class ChildrenSupportModule

  # Filet du job d'attribution : un livre que l'export logistique n'a pas enregistré
  # n'apparaîtrait ni sur la fiche de suivi ni en « Non envoyé ». On le signale, sans rien écrire.
  class CheckBooksSavedService

    MESSAGE = "Des livres n'ont pas été enregistrés à l'export logistique".freeze

    attr_reader :errors

    def initialize(group_ids:)
      @group_ids = group_ids
      @errors = []
    end

    def call
      unsaved_modules.group_by { |csm| csm.child.group_id }.each do |group_id, children_support_modules|
        @errors << { message: MESSAGE, context: { group_id: group_id, children_support_module_ids: children_support_modules.map(&:id) } }
      end
      self
    end

    private

    # les modules que l'export aurait dû enregistrer : parent 1, non programmés, enfant suivi, module avec un livre
    # (csm[:book_id] : book_id est délégué au livre)
    def unsaved_modules
      ChildrenSupportModule.chosen_modules_for_group(@group_ids, include_unshippable: true)
                           .select { |csm| csm.child.group_status.in?(ChildrenSupportModule::BOOK_TRACKED_GROUP_STATUSES) }
                           .select { |csm| csm[:book_id].nil? && csm.support_module_book_id.present? }
    end
  end
end
