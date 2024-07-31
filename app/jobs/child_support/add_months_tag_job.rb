class ChildSupport
  class AddMonthsTagJob < ApplicationJob
    def perform(group_id)
      lt22_tag = Tag.find_or_create_by(name: '<22mois', color: '#00fbff')
      mt23_tag = Tag.find_or_create_by(name: '23 mois et +', color: '	#ff9500')
      group = Group.includes(child_supports: :children).find(group_id)
      group.child_supports.with_a_child_in_active_group.find_each do |child_support|
        child_support.tag_list.add(child_support.current_child.months < 22 ? lt22_tag.name : mt23_tag.name)
        child_support.save
      end
    end
  end
end
