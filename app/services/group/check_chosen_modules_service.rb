class Group

  # Refus d'un export logistique manuel : les choix de modules de la cohorte doivent être prêts à expédier
  class CheckChosenModulesService

    attr_reader :errors

    def initialize(groups:)
      @groups = groups
      @errors = []
    end

    def call
      @groups.each do |group|
        children_support_modules = ChildrenSupportModule.where(child_id: group.active_children_ids, is_programmed: false)

        if children_support_modules.where.not(support_module_id: nil).none?
          @errors << { message: "Les modules de la cohorte #{group.name} ont déjà été programmés", context: { group_id: group.id } }
        elsif children_support_modules.exists?(support_module_id: nil)
          @errors << { message: "Dans la cohorte #{group.name}, il y a des enfants sans choix de module.", context: { group_id: group.id } }
        end
      end
      self
    end
  end
end
