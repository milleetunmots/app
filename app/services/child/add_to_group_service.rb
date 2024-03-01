class Child

  class AddToGroupService

    attr_reader :child, :group

    def initialize(child_id)
      @group = nil
      @siblings = Child.find(child_id).siblings
      # Le oldest de moins de 30 mois
      @oldest_child = @siblings.order(:birthdate).first
    end

    def call
      retrieve_next_available_group
      add_to_group
      self
    end

    private

    def retrieve_next_available_group
      @group = @siblings.first_active_group || (@oldest_child.months >= 4 ? Group.next_available_at(Time.zone.today) : Group.next_available_at(@oldest_child.birthdate + 4.months))
    end

    def add_to_group
      return unless @group

      if @group.started?
        @siblings.each do |child|
          next if child.birthdate + 6.months > @group.started_at

          child.update(group: @group, group_status: child.months >= 36 ? 'stopped' : 'active')
        end
      else
        @siblings.each do |child|
          next if child.birthdate + 4.months > @group.started_at

          child.update(group: @group, group_status: child.months >= 30 ? 'stopped' : 'active')
        end
      end
    end
  end
end
