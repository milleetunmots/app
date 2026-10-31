module ActiveAdmin::ChildrenSupportModulesHelper

  # « Non envoyé » n'est proposé qu'à ceux qui peuvent le poser ; il reste listé
  # quand il est déjà posé pour que le select (alors désactivé) l'affiche
  def book_condition_select_collection(can_manage_not_sent:, current_condition: nil)
    conditions = ChildrenSupportModule::CONDITIONS
    conditions -= [ChildrenSupportModule::NOT_SENT] unless can_manage_not_sent || current_condition == ChildrenSupportModule::NOT_SENT
    conditions.map do |v|
      [
        ChildrenSupportModule.human_attribute_name("condition.#{v}"),
        v
      ]
    end
  end

end
