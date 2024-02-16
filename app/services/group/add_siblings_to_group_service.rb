class Group

  class AddSiblingsToGroupService

    def initialize(group_id)
      @group = Group.find(group_id)
    end

    def call
      @group.children.only_siblings.find_each do |child|
        next unless child.current_child?

        child.siblings.each do |sibling|
          next unless sibling.group_status == 'waiting' && sibling.months >= 6

          sibling.group = @group
          sibling.group_status = 'active'
          sibling.save
        end
      end

      self
    end
  end
end
