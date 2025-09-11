module TagsSharedConcern
  extend ActiveSupport::Concern

  included do
    before_update :remove_tags
    before_update :add_tags

    private

    def find_child_support
      return child_support if respond_to?(:child_support)

      current_child&.child_support if respond_to?(:current_child)
    end

    def old_tag_list
      return unless tag_list_changed?

      tag_list_change.first
    end

    def new_tag_list
      return unless tag_list_changed?

      tag_list_change.last
    end

    def tags_to_add
      new_tag_list.to_a - old_tag_list.to_a
    end

    def tags_to_remove
      old_tag_list.to_a - new_tag_list.to_a
    end

    def add_tags_to(element)
      return if tags_to_add.blank?

      element.tag_list.add(tags_to_add)
      element.save(validate: false)
    end

    def remove_tags_from(element)
      return if tags_to_remove.blank?

      element.tag_list.remove(tags_to_remove)
      element.save(validate: false)
    end

    def add_tags_to_parent1
      return unless instance_of?(Parent)
      return if self == current_child&.parent1

      add_tags_to(current_child&.parent1)
    end

    def add_tags_to_parent2
      return unless instance_of?(Parent)
      return unless current_child&.parent2
      return if self == current_child&.parent2

      add_tags_to(current_child&.parent2)
    end

    def add_tags_to_parents
      add_tags_to_parent1
      add_tags_to_parent2
      return if instance_of?(Parent)
      return unless parent1

      add_tags_to(parent1)
      return unless parent2

      add_tags_to(parent2)
    end

    def add_tags_to_children
      return if instance_of?(Child)
      return if children.blank?

      children.each do |child|
        add_tags_to(child)
      end
    end

    def add_tags_to_siblings
      return unless instance_of?(Child)

      siblings.each do |sibling|
        add_tags_to(sibling)
      end
    end

    def add_tags_to_child_support
      return if instance_of?(ChildSupport)
      return unless find_child_support

      add_tags_to(find_child_support)
    end

    def remove_tags_from_parent1
      return unless instance_of?(Parent)
      return if self == current_child&.parent1

      remove_tags_from(current_child&.parent1)
    end

    def remove_tags_from_parent2
      return unless instance_of?(Parent)
      return unless current_child&.parent2
      return if self == current_child&.parent2

      remove_tags_from(current_child&.parent2)
    end

    def remove_tags_from_parents
      remove_tags_from_parent1
      remove_tags_from_parent2
      return if instance_of?(Parent)
      return unless parent1

      remove_tags_from(parent1)
      return unless parent2

      remove_tags_from(parent2)
    end

    def remove_tags_from_children
      return if instance_of?(Child)
      return if children.blank?

      children.each do |child|
        remove_tags_from(child)
      end
    end

    def remove_tags_from_siblings
      return unless instance_of?(Child)

      siblings.each do |sibling|
        remove_tags_from(sibling)
      end
    end

    def remove_tags_from_child_support
      return if instance_of?(ChildSupport)
      return unless find_child_support

      remove_tags_from(find_child_support)
    end

    def add_tags
      return if tags_to_add.blank?

      add_tags_to_child_support
      add_tags_to_parents
      add_tags_to_children
      add_tags_to_siblings
    end

    def remove_tags
      return if tags_to_remove.blank?

      remove_tags_from_child_support
      remove_tags_from_parents
      remove_tags_from_children
      remove_tags_from_siblings
    end
  end
end
