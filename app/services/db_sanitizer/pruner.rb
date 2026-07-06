# frozen_string_literal: true

module DbSanitizer
  class Pruner
    def initialize(months_to_keep)
      @months_to_keep = months_to_keep
    end

    def call
      kept_group_ids = Group.where('created_at >= ?', @months_to_keep.months.ago).ids

      if kept_group_ids.empty?
        Rails.logger.warn "[DbSanitizer::Pruner] No groups found in last #{@months_to_keep} months — skipping pruning"
        return
      end

      kept_parent_ids = find_kept_parent_ids(kept_group_ids)
      children_to_delete_ids = Child.where.not(parent1_id: kept_parent_ids).ids

      return if children_to_delete_ids.empty?

      delete_children_dependents(children_to_delete_ids)
      Child.where(id: children_to_delete_ids).delete_all

      delete_orphaned_child_supports
      delete_orphaned_parents(kept_parent_ids)
    end

    private

    def find_kept_parent_ids(kept_group_ids)
      pairs = Child.where(group_id: kept_group_ids).pluck(:parent1_id, :parent2_id)
      pairs.flat_map { |p1, p2| [p1, p2] }.compact.uniq
    end

    def delete_children_dependents(child_ids)
      ChildrenSupportModule.where(child_id: child_ids).delete_all
      ChildrenSource.where(child_id: child_ids).delete_all
      RedirectionUrl.where(child_id: child_ids).delete_all
      ActsAsTaggableOn::Tagging.where(taggable_type: 'Child', taggable_id: child_ids).delete_all
    end

    def delete_orphaned_child_supports
      orphaned_ids = ChildSupport
        .where.not(id: Child.select(:child_support_id).where.not(child_support_id: nil))
        .ids
      return if orphaned_ids.empty?

      ActsAsTaggableOn::Tagging.where(taggable_type: 'ChildSupport', taggable_id: orphaned_ids).delete_all
      ScheduledCall.where(child_support_id: orphaned_ids).delete_all
      ChildSupportCallArchive.where(child_support_id: orphaned_ids).delete_all
      ChildSupport.where(id: orphaned_ids).delete_all
    end

    def delete_orphaned_parents(kept_parent_ids)
      orphaned_parent_ids = Parent.where.not(id: kept_parent_ids).ids
      return if orphaned_parent_ids.empty?

      ActsAsTaggableOn::Tagging
        .where(taggable_type: 'Parent', taggable_id: orphaned_parent_ids)
        .delete_all

      ParentsAnswer.where(parent_id: orphaned_parent_ids).delete_all

      connection = ActiveRecord::Base.connection
      parent_ids_sql = orphaned_parent_ids.join(',')
      connection.execute("DELETE FROM parents_workshops WHERE parent_id IN (#{parent_ids_sql})")

      RedirectionUrl.where(parent_id: orphaned_parent_ids).delete_all
      ParentsRegistration.where(parent1_id: orphaned_parent_ids)
                         .or(ParentsRegistration.where(parent2_id: orphaned_parent_ids))
                         .delete_all
      ScheduledCall.where(parent_id: orphaned_parent_ids).delete_all
      Parent.where(id: orphaned_parent_ids).delete_all
    end
  end
end
