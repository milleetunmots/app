module TagsSharedConcern
  extend ActiveSupport::Concern

  included do
    before_update :remove_tags
    before_update :add_tags

    private

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

    def add_tags_to_parents
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

    def add_tags_to_child_support
      return if instance_of?(ChildSupport)
      return unless child_support

      add_tags_to(child_support)
    end

    def remove_tags_from_parents
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

    def remove_tags_from_child_support
      return if instance_of?(ChildSupport)

      element = if respond_to?(:child_support)
                  child_support
                elsif respond_to?(:current_child)
                  current_child&.child_support
                end
      return unless element

      remove_tags_from(element)
    end

    def add_tags
      return if instance_of?(Parent)
      return if tags_to_add.blank?

      add_tags_to_parents
      add_tags_to_children
      return if instance_of?(Child)

      add_tags_to_child_support
    end

    def remove_tags
      return if tags_to_remove.blank?

      remove_tags_from_parents
      remove_tags_from_children
      remove_tags_from_child_support
    end

    def distribute_tags_to(element)
      element.tag_list.add(tags_to_add) if tags_to_add.present?
      element.tag_list.remove(tags_to_remove) if tags_to_remove.present?
      element.save(validate: false)
    end

    def distribute_tags_to_parents
      return unless parent1
      return unless tag_list_changed?

      distribute_tags_to(parent1)
      return unless parent2

      distribute_tags_to(parent2)
    end

    def distribute_tags_to_children
      return if children.blank?
      return unless tag_list_changed?

      children.each do |child|
        distribute_tags_to(child)
      end
    end
  end
end
