class Child

  class HandleDuplicateService

    def initialize
      @duplicated_parents_by_phone_number = Parent.kept.potential_duplicates.group_by(&:phone_number)
      @children_duplicated_name_and_birthdate = Child.kept.potential_duplicates.group_by(&:name_and_birthdate)
    end

    def call
      handle_duplicated_parents_by_phone_number
      handle_children_duplicated_name_and_birthdate
      self
    end

    private

    def handle_duplicated_parents_by_phone_number
      @duplicated_parents_by_phone_number.each do |phone_number, parents|
        @parents = parents.sort_by(&:id)
        @phone_number = phone_number
        @children = Child.kept.left_outer_joins(:parent1, :parent2).where(parents: { phone_number: @phone_number.to_s })
        @waiting_children = @children.pending_support.sort_by(&:id)
        @not_waiting_children = @children.where.not(group_status: %w[stopped disengaged]).not_pending_support.sort_by(&:id)
        if only_duplicated_children?
          keep_only_one_family
        else
          move_children_to_a_single_child_support
        end
      end
    end

    def only_duplicated_children?
      first_parent = @parents.first
      all_parents_except_first = @parents.drop(1)
      all_parents_except_first.all? { |parent| first_parent.only_duplicated_children_with?(parent) }
    end

    def keep_only_one_family
      return if many_parents_with_supported_children?

      parent_to_keep = @not_waiting_children.empty? ? @parent.first : @not_waiting_children.first.parent1
      @parent.each do |parent|
        next if parent.id == parent_to_keep.id

        parent.children.each do |child|
          child.group_status = 'not_supported'
          child.save!
          child.child_support&.discard
          child.discard
        end
        parent.discard
      end
    end

    def many_parents_with_supported_children?
      first_parent1_id = @not_waiting_children.first.parent1_id
      not_waiting_children_except_first = @not_waiting_children.drop(1)
      not_waiting_children_except_first.any? { |child| child.parent1_id != first_parent1_id }
    end

    def move_children_to_a_single_child_support
      @child_support = single_child_support
      return unless @child_support

      @waiting_children.each do |child|
        @child = child
        next unless @child.child_support

        retrieve_old_associations
        change_parents_and_child_support
        discard_old_associations
      end
    end

    def single_child_support
      return nil if @waiting_children.empty?

      first_child = @not_waiting_children.empty? ? @waiting_children.shift : @not_waiting_children.first
      first_child.child_support
    end

    def retrieve_old_associations
      @old_parent1 = @child.parent1
      @old_parent2 = @child.parent2 if @child.parent2
      @old_child_support = @child.child_support
    end

    def change_parents_and_child_support
      @child_support.copy_fields(@child.child_support)
      @child_support.save

      @child.parent1_id = @child_support.parent1.id
      @child.parent2_id = @child_support.parent2.id if @child_support.parent2
      @child.child_support_id = @child_support.id
      @child.save(validate: false)
    end

    def discard_old_associations
      @old_parent1.discard if @old_parent1.children.empty?
      @old_parent2&.discard if @old_parent2 && @old_parent2&.children&.empty?
      @old_child_support.discard if @old_child_support.children.empty?
    end

    def handle_children_duplicated_name_and_birthdate
      @children_duplicated_name_and_birthdate.each do |_, children|
        @children = children
        next if any_child_with_parent2?

        next if more_than_one_children_supported?

        next if any_parent_have_others_children?

        phone_numbers = parents_phone_numbers
        next if phone_numbers.count != 2

        waiting_children = Child.where(id: @children.map(&:id)).pending_support.sort_by(&:id)
        not_waiting_children = Child.where(id: @children.map(&:id)).where.not(group_status: %w[stopped disengaged]).not_pending_support.sort_by(&:id)
        next if waiting_children.empty?

        @first_parent = Parent.find_by(phone_number: phone_numbers.first)
        @second_parent = Parent.find_by(phone_number: phone_numbers.second)
        @child = not_waiting_children.empty? ? waiting_children.first : not_waiting_children.first
        link_families
      end
    end

    def any_child_with_parent2?
      @children.any? { |child| child.parent2.present? }
    end

    def more_than_one_children_supported?
      @children.count { |child| child.group_status == 'active' && child.group.started_at.present? && child.group.started_at <= Time.zone.today } > 1
    end

    def any_parent_have_others_children?
      @children.any? do |child|
        child.siblings.any? { |sibling| !@children.include? sibling }
      end
    end

    def parents_phone_numbers
      phone_numbers = []
      @children.each do |child|
        phone_numbers << child.parent1.phone_number
        phone_numbers << child.parent2.phone_number if child.parent2
      end
      phone_numbers.uniq
    end

    def link_families
      @child.parent1 = @first_parent
      @child.parent2 = @second_parent
      @child.save
      @children.each do |child|
        next if child.id == @child.id

        child.discard
        child.child_support.discard if child.children.empty?
      end
    end
  end
end
