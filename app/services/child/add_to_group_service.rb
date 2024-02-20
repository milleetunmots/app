class Child

  class AddToGroupService

    attr_reader :child, :group

    def initialize(child_id)
      @child = Child.find(child_id)
      @group = nil
    end

    def call
      # Quand l'enfant est seul
      if @child.siblings.count == 1
        retrieve_next_available_group(@child)
        @child.update(group: @group, group_status: 'active') if @group
      else
        # At the start of each module >= 2 (FillParentsAvailableSupportModulesJob), we add siblings >= 6 months to the group
        return self if @child.siblings.any? { |sibling| sibling.group.started? && sibling.group_status == 'active' }

        # Aucun membre de la fratrie n'est suivi
        assign_group_to_all_siblings and return self if @child.siblings.none? { |sibling| sibling.group_status == 'active' }

        # Au moins un membre de la fratrie est suivi mais le groupe n'a pas commencé
        join_sibling_group
      end
      self
    end

    private

    def retrieve_next_available_group(child)
      @group = child.months >= 4 ? Group.next_available_at(Time.zone.today) : Group.next_available_at(child.birthdate + 4.months)
    end

    def assign_group_to_all_siblings
      retrieve_next_available_group(@child.youngest_sibling)
      return self unless @group

      @child.siblings.each do |sibling|
        next if sibling.birthdate + 30.months > @group.started_at

        sibling.update(group: @group, group_status: 'active')
      end
    end

    def join_sibling_group
      sibling_group = @child.siblings.where(group_status: 'active').first.group
      return if @child.birthdate + 4.months < sibling_group.started_at

      @child.update(group: sibling_group, group_status: 'active')
    end
  end
end
