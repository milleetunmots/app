class Group

  class DistributeChildrenToSupportersService

    # children_count_by_supporter = [
    #   { admin_user_id: 1, children_count: 15 },
    #   { admin_user_id: 2, children_count: 10 },
    #   ...
    # ]
    def initialize(group, children_count_by_supporter)
      @group = group
      @children_count_by_supporter = children_count_by_supporter
    end

    def call
      balance_capacity_of_each_supporter

      child_support_by_category = order_child_supports

      associate_children_to_supporters(child_support_by_category)
    end

    private

    def balance_capacity_of_each_supporter
      total_capacity = @children_count_by_supporter.sum { |h| h[:children_count] }
      total_child_supports_count = @group.child_supports.uniq.count

      while total_capacity != total_child_supports_count
        @children_count_by_supporter.each do |supporter_capacity|
          break if total_capacity == total_child_supports_count

          sign = total_capacity > total_child_supports_count ? -1 : 1

          supporter_capacity[:children_count] += sign
          total_capacity += sign
        end
      end
    end

    def order_child_supports
      @group.child_supports.uniq.group_by { |c| c.postal_code.first(2) }
    end

    def associate_children_to_supporters(children_by_category)
      @children_count_by_supporter.each do |supporter_with_capacity|
        while supporter_with_capacity[:children_count].positive?
          category = children_by_category.find { |_, children| children.count == supporter_with_capacity[:children_count] }
          category ||= children_by_category.find { |_, children| children.count > supporter_with_capacity[:children_count] }
          category ||= children_by_category.first

          while category[1].any?
            child_support = category[1].shift
            child_support.update(supporter_id: supporter_with_capacity[:admin_user_id])
            supporter_with_capacity[:children_count] -= 1
            break if supporter_with_capacity[:children_count].zero?
          end
        end
      end
    end
  end
end
