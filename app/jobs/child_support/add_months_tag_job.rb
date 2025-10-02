class ChildSupport
  class AddMonthsTagJob < ApplicationJob
    def perform(group_id)
      lt9_tag = Tag.find_or_create_by(name: '<9mois', color: '#ff9500', is_visible_by_callers_and_animators: true)
      btw9_and22_tag = Tag.find_or_create_by(name: '9 à 22 mois', color: '#00fbff', is_visible_by_callers_and_animators: true)
      mt23_tag = Tag.find_or_create_by(name: '23 mois et +', color: '#ff9500', is_visible_by_callers_and_animators: true)
      group = Group.includes(child_supports: :children).find(group_id)
      group.child_supports.with_a_child_in_active_group.find_each do |child_support|
        child_support.tag_list +=
          if child_support.current_child.months < 9
            [lt9_tag].flatten
          elsif child_support.current_child.months < 23
            [btw9_and22_tag].flatten
          else
            [mt23_tag].flatten
        end
        child_support.save
      end
    end
  end
end
