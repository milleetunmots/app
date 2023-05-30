class Group

  class DistributeChildSupportsToSupportersService

    # children_count_by_supporter = [
    #   { admin_user_id: 1, child_supports_count: 15 },
    #   { admin_user_id: 2, child_supports_count: 10 },
    #   ...
    # ]
    def initialize(group, child_supports_count_by_supporter)
      @group = group
      @child_supports_count_by_supporter = child_supports_count_by_supporter
    end

    def call
      balance_capacity_of_each_supporter

      child_supports_order_by_category = order_child_supports

      associate_child_support_to_supporters(child_supports_order_by_category)
    end

    private

    def order_by_child_supports_count
      @child_supports_count_by_supporter.sort! { |first, second| second[:child_supports_count] <=> first[:child_supports_count] }
    end

    def balance_capacity_of_each_supporter
      total_capacity = @child_supports_count_by_supporter.sum { |h| h[:child_supports_count] }
      total_child_supports_count = @group.child_supports.uniq.count
      order_by_child_supports_count

      while total_capacity != total_child_supports_count
        @child_supports_count_by_supporter.each do |supporter_capacity|
          break if total_capacity == total_child_supports_count

          sign = total_capacity > total_child_supports_count ? -1 : 1

          supporter_capacity[:child_supports_count] += sign
          total_capacity += sign
        end
      end
    end

    def order_child_supports
      @group.child_supports.uniq.sort_by { |child_support| [child_support.registration_source, child_support.postal_code.first(2)] }
    end

    def associate_child_support_to_supporters(child_supports_order_by_category)
      index = 0
      @child_supports_count_by_supporter.each do |supporter_with_capacity|
        while supporter_with_capacity[:child_supports_count].positive?
          child_support = child_supports_order_by_category[index]
          index += 1
          child_support.update(supporter_id: supporter_with_capacity[:admin_user_id])
          supporter_with_capacity[:child_supports_count] -= 1
        end
      end
    end
  end
end
