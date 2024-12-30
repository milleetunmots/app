class Child

  class HandleDuplicateService

    def initialize
      @duplicated_parents_by_phone_number = Parent.kept.potential_duplicates.group_by(&:phone_number)
      duplicated_children_name_and_birthdate = Child.kept.potential_duplicates.group_by(&:name_and_birthdate)
      @duplicated_children_with_parent2, @duplicated_children_without_parent2 = duplicated_children_name_and_birthdate.partition do |_, children|
        children.any? { |child| child.parent2.present? }
      end
    end

    def call
      handle_duplicated_parents_by_phone_number
      handle_duplicated_children_without_parent2
      handle_duplicated_children_with_parent2
      self
    end

    private

    def handle_case_three
      @groups = children_groups
      # If at least one group has not started
      return unless @groups.empty? || @waiting_children.any?

      first_child = @children.sort_by(&:created_at).first
      @children.pending_support.where.not(id: first_child.id).each do |child|
        child.parent1.discard
        child.parent2.discard
        child.child_support&.discard
        child.update(
          parent1: first_child.parent1,
          parent2: first_child.parent2,
          child_support: first_child.child_support
        )
      end
    end

    def handle_duplicated_parents_by_phone_number
      @duplicated_parents_by_phone_number.each do |phone_number, parents|
        @parents = parents.sort_by(&:id)
        @phone_number = phone_number
        @children = Child.kept.left_outer_joins(:parent1, :parent2).where(parents: { phone_number: @phone_number.to_s })
        @waiting_children = @children.pending_support.sort_by(&:id)
        @not_waiting_children = @children.where.not(group_status: %w[stopped disengaged not_supported]).not_pending_support.sort_by(&:id)

        case
        when any_child_with_parent2?
          handle_case_three if case_three?
        when only_duplicated_children?
          keep_only_one_family
        else
          move_children_to_a_single_child_support
        end
      end
    end

    def handle_duplicated_children_without_parent2
      @duplicated_children_without_parent2.each do |_, children|
        @children = children
        next if any_child_with_parent2?

        next if more_than_one_children_supported?

        next if any_parent_have_others_children?

        phone_numbers = all_parents_phone_numbers
        next if phone_numbers.count != 2

        waiting_children = Child.where(id: @children.map(&:id)).pending_support.sort_by(&:id)
        not_waiting_children = Child.where(id: @children.map(&:id)).where.not(group_status: %w[stopped disengaged not_supported]).not_pending_support.sort_by(&:id)
        next if waiting_children.empty?

        @first_parent = Parent.find_by(phone_number: phone_numbers.first)
        @second_parent = Parent.find_by(phone_number: phone_numbers.second)
        @child = not_waiting_children.empty? ? waiting_children.first : not_waiting_children.first
        link_families
      end
    end

    def handle_case_one
      # S'il n'y a pas de cohorte ou si celles qui existent n'ont pas encore démarré
      if @groups.empty? || ( @groups.all? { |group| group.started_at.present? && (group.started_at >= Time.zone.today) && group.support_module_programmed.zero? })
        delete_children_without_parent2
        keep_recent_child
      # Si une seule cohorte a démarré
      elsif @started_groups.length == 1
        keep_supported_children_and_add_parent2_if_needed
      end
    end

    def handle_case_two
      if @groups.empty? || (@groups.all? { |group| group.started_at.present? && (group.started_at >= Time.zone.today) && group.support_module_programmed.zero? })
        # Si il n'existe pas de cohortes actives, supprimer les doublons les plus récents
        @children.sort_by(&:created_at).drop(1).each do |child|
          discard_child(child)
        end
      elsif @started_groups.length == 1
        @children.select { |child| child.group_id != @started_groups.first.id }.each do |child|
          discard_child(child)
        end
      end
    end

    def discard_child(child)
      if child.group_id
        child.group_status = 'not_supported'
        child.save!
      end
      child.discard
      child.parent1.discard if child.parent1.children.kept.empty?
      child.parent2.discard if child.parent2 && child.parent2.children.kept.empty?
      child.child_support.discard if child.child_support.children.kept.empty?
    end

    def keep_supported_children_and_add_parent2_if_needed
      started_group_children = @children.select { |child| child.group_id.to_i == @started_groups.first.id }
      not_supported_children = @children - started_group_children
      parent2 = @children.select { |child| child.parent2.present? }.first&.parent2
      started_group_children.select { |child| child.parent2.nil? }.each do |child|
        # Il n'y a qu'un seul enfant suivi normalement
        child.parent2 = parent2
        child.save
      end
      not_supported_children.each do |child|
        if child.group_id
          child.group_status = 'not_supported'
          child.save!
        end
        child.discard
        child.parent1.discard if child.parent1.children.kept.empty?
        next if child.child_support.nil?

        child.child_support.discard if child.child_support.children.kept.empty?
      end
    end

    def delete_children_without_parent2
      # On conserve l'enfant qui a le plus de parents en supprimant ceux qui n'ont pas de parent2, leur parent1 et leur fiche de suivi
      @children.select { |child| child.parent2.nil? }.each do |child_without_parent2|
        if child_without_parent2.group_id
          child_without_parent2.group_status = 'not_supported'
          child_without_parent2.save!
        end
        child_without_parent2.discard
        child_without_parent2.parent1.discard if child_without_parent2.parent1.children.kept.empty?
        next if child_without_parent2.child_support.nil?

        child_without_parent2.child_support.discard if child_without_parent2.child_support.children.kept.empty?
      end
    end

    def keep_recent_child
      # Et si plusieurs ont des parent2, on garde le plus récent
      @children.select { |child| child.parent2.present? }.sort_by(&:created_at).reverse.drop(1).each do |child_with_parent2|
        if child_with_parent2.group_id
          child_with_parent2.group_status = 'not_supported'
          child_with_parent2.save!
        end
        child_with_parent2.discard
        child_with_parent2.parent1.discard if child_with_parent2.parent1.children.kept.empty?
        next if child_with_parent2.child_support.nil?

        child_with_parent2.child_support.discard if child_with_parent2.child_support.children.kept.empty?
      end
    end

    def handle_duplicated_children_with_parent2
      @duplicated_children_with_parent2.each do |_, children|
        next if more_than_one_children_supported?

        @children = children
        # Recupérer les cohortes
        @groups = children_groups
        @started_groups = @groups.select { |group| group.started_at.present? && (group.started_at <= Time.zone.today) && group.support_module_programmed.positive? }
        case
        when case_one?
          handle_case_one
        when case_two?
          handle_case_two
        end
      end
    end

    def any_child_with_parent2?
      @children.any? { |child| child.parent2.present? }
    end

    def only_duplicated_children?
      # returns true if all the parents have the "same" children or dont have one
      parents = Parent.where(id: @parents.map(&:id))
      first_parent = parents.joins("JOIN children ON (children.parent1_id = parents.id OR children.parent2_id = parents.id) AND children.discarded_at IS NULL").first
      return true if first_parent.nil?

      all_parents_except_first = parents.where.not(id: first_parent.id)
      all_parents_except_first.all? { |parent| first_parent.only_duplicated_children_with?(parent) }
    end

    def keep_only_one_family
      return if many_parents_with_supported_children?

      parent_to_keep = @not_waiting_children.empty? ? @parents.first : @not_waiting_children.first.parent1
      @parents.each do |parent|
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
      return false if @not_waiting_children.empty?

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
      return if @old_child_support.blank?

      @old_child_support.discard if @old_child_support.children.kept.empty?
    end

    def more_than_one_children_supported?
      @children.count { |child| child.group_status == 'active' && child.group&.started_at.present? && child.group.started_at <= Time.zone.today && child.group.support_module_programmed.to_i.positive? } > 1
    end

    def any_parent_have_others_children?
      @children.any? do |child|
        child.siblings.kept.any? { |sibling| !@children.include?(sibling) }
      end
    end

    def all_parents_phone_numbers
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

        if child.group_id
          child.group_status = 'not_supported'
          child.save!
        end
        child.discard
        child.child_support.discard if child.child_support.children.kept.empty?
      end
    end

    def case_one?
      only_child? && common_parent? && at_least_one_child_without_parent2?
    end

    def case_two?
      only_child? && common_parent1_and_parent2? && all_children_with_parent2?
    end

    def case_three?
      only_child? && differents_children? && common_parent1_and_parent2? && all_children_with_parent2?
    end

    def only_child?
      @children.none? { |child| child.siblings.size > 1 }
    end

    def common_parent?
      all_parents_phone_numbers.any? do |phone_number|
        @children.all? { |child| child.parent1.phone_number == phone_number || child.parent2&.phone_number == phone_number }
      end
    end

    def common_parent1_and_parent2?
      return false unless child_with_parent2_parents_phone_numbers

      child_with_parent2_parents_phone_numbers.all? do |phone_number|
        @children.all? { |child| child.parent1.phone_number == phone_number || child.parent2&.phone_number == phone_number }
      end
    end

    def at_least_one_child_without_parent2?
      @children.any? { |child| child.parent2.nil? }
    end

    def all_children_with_parent2?
      @children.all? { |child| child.parent2.present? }
    end

    def differents_children?
      @children.map { |child| [child.first_name.downcase.gsub(/[^a-z]/, ''), child.last_name.downcase.gsub(/[^a-z]/, ''), child.birthdate] }.uniq.size == @children.size
    end

    def child_with_parent2_parents_phone_numbers
      @children.select { |child| child.parent2.present? }.map { |child| [child.parent1.phone_number, child.parent2.phone_number] }.first
    end

    def children_groups
      Group.where(id: @children.pluck(:group_id).uniq.compact_blank)
    end
  end
end
