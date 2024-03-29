class Child

  class HandleDuplicateService

    attr_reader :children

    def initialize

      ## group les parents en duplicate par numéro de téléphone
# { numero => [parentX, parentY],
#   numero2 => [parent3, parent4] }
#   SI tous les parents ont des enfants déjà suivis, on next
#   Sinon on met les enfants pas encore accompagnés dans la fiche des enfants déjà accompagnés

      @duplicated_parents_by_phone_number = Parent.kept.potential_duplicates.group_by(&:phone_number)
      # @duplicate_children_by_name_and_birthdate = Child.potential_duplicates.group_by(&:last_name, &:first_name, &:birthdate)
      @children = []
    end

    def call
      @duplicated_parents_by_phone_number.each do |phone_number, parents|
        if has_only_duplicated_children?(parents)
          keep_only_one_family
        else
          move_children_to_a_single_child_support(parents)
          delete_empty_child_supports(parents)
          delete_empty_parents(parents)
        end
      end

    # @duplicate_children_by_name_and_birthdate.do |child|

    # end






      # @duplicated_parents_by_phone_number.each do |phone_number, _|
      #   waiting_children = Child.kept.left_outer_joins(:parent1, :parent2).where(parents: { phone_number: phone_number.to_s }).pending_support.sort_by(&:id)
      #   not_waiting_children = Child.kept.left_outer_joins(:parent1, :parent2).where(parents: { phone_number: phone_number.to_s }).not_pending_support.sort_by(&:id)

      #   next if waiting_children.empty?

      #   first_child = not_waiting_children.empty? ? waiting_children.shift : not_waiting_children.shift

      #   waiting_children.each do |child|
      #     next unless first_child.child_support
      #     next unless child.child_support

      #     old_parent1 = child.parent1
      #     old_parent2 = child.parent2 if child.parent2
      #     old_child_support = child.child_support

      #     first_child.child_support.copy_fields(child.child_support)
      #     first_child.child_support.save
      #     child.parent1_id = first_child.parent1_id
      #     child.parent2_id = first_child.parent2_id if first_child.parent2
      #     child.child_support_id = first_child.child_support_id
      #     child.save(validate: false)

      #     old_parent1.destroy if old_parent1.children.empty?
      #     old_parent2&.destroy if old_parent2 && old_parent2&.children&.empty?
      #     old_child_support.destroy if old_child_support.children.empty?
      #   end

      #   (@duplicate_children_by_name_and_birthdate.to_a & first_child.siblings.to_a).drop(1).each { |child| child.destroy }


      # end


      # @duplicate_phone_numbers.each do |number|
      #   waiting_children = Child.kept.left_outer_joins(:parent1, :parent2).where(parents: { phone_number: number }).where(group_status: 'waiting').order(:created_at)
      #   waiting_children_array = waiting_children.to_a



      #   next if waiting_children.size <= 1

      #   byebug

      #   first_child = waiting_children_array.shift

      #   waiting_children_array.each do |child|
      #     next unless first_child.child_support

      #     first_child.child_support.copy_fields(child.child_support)
      #     first_child.child_support.save
      #     child.parent1_id = first_child.parent1_id
      #     child.parent2_id = first_child.parent2_id if first_child.parent2
      #     child.child_support_id = first_child.child_support.id
      #     child.save(validate: false)
      #     child.child_support.destroy if child.child_support.children.empty?
      #   end

      #   @children << first_child.id

      # end
      self
    end
  end
end
