class Group

  class DistributeChildSupportsToSupportersService

    # child_supports_count_by_supporter = [
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

      child_supports_order_by_registration_source = order_child_supports

      associate_child_support_to_supporters(child_supports_order_by_registration_source)
      # associate_child_support_to_supporters(child_supports_order_by_registration_source)
    end

    private

    def order_by_child_supports_count
      @child_supports_count_by_supporter.sort! { |first, second| second[:child_supports_count] <=> first[:child_supports_count] }
    end

    def balance_capacity_of_each_supporter
      total_capacity = @child_supports_count_by_supporter.sum { |h| h[:child_supports_count] }
      total_child_supports_count = @group.child_supports.joins(:children).where(children: { group_status: 'active' }).uniq.count
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
      # we want to order child_supports by registration_source, then by land, then by department
      child_supports_order_by_registration_source = @group.child_supports.joins(:children).where(children: { group_status: 'active' }).uniq.group_by(&:registration_source)

      child_supports_order_by_registration_source.each do |registration_source, child_supports|
        case registration_source
        when 'pmi'
          # order each registration_source by pmi_detail
          child_supports_order_by_registration_source[registration_source] = child_supports.group_by { |child_support| child_support.pmi_detail }
        when 'caf'
          # order each registration_source by registration_source_details
          child_supports_order_by_registration_source[registration_source] = child_supports.group_by { |child_support| child_support.registration_source_details }
        else
          # order each registration_source by land
          child_supports_order_by_registration_source[registration_source] = child_supports.group_by { |child_support| child_support.decorate.land }
        end

        # some child_supports doesn't have a land, so they are present in a key nil
        # we take them out of the hash
        left_overs_child_supports = child_supports_order_by_registration_source[registration_source].delete(nil)

        next if left_overs_child_supports.nil?

        # we sort them by department
        child_supports_by_department = left_overs_child_supports.group_by { |child_support| child_support.postal_code.first(2) }

        # we merge them back into the hash
        child_supports_order_by_registration_source[registration_source].merge!(child_supports_by_department)
      end
    end

    def associate_child_support_to_supporters(child_supports_order_by_registration_source)
      smallest_registration_sources_first = child_supports_order_by_registration_source.to_a.sort do |first, second|
        # first = [registration_source, { land => [child_supports], other_land => [child_supports] }]
        # second = [registration_source, { land => [child_supports], other_land => [child_supports] }]

        first[1].values.sum(&:size) <=> second[1].values.sum(&:size)
      end

      other_by_supporter = {}
      not_pmi_caf_or_friends = {}
      siblings_by_supporter = {}

      4.times do |index|
        smallest_registration_sources_first.each do |registration_source|
          registration_source[1].each do |land, child_supports|
            @child_supports_count_by_supporter.each do |supporter_with_capacity|
              siblings_by_supporter[supporter_with_capacity[:admin_user_id]] ||= 0

              child_supports.each do |child_support|
                break if supporter_with_capacity[:child_supports_count].zero?
                next if child_support.children.count == 1 && index < 1

                if child_support.children.count > 1
                  next if siblings_by_supporter[supporter_with_capacity[:admin_user_id]] == 4

                  siblings_by_supporter[supporter_with_capacity[:admin_user_id]] += 1
                end

                if registration_source[0] == 'other'
                  other_by_supporter[supporter_with_capacity[:admin_user_id]] ||= 0
                  other_by_supporter[supporter_with_capacity[:admin_user_id]] += 1
                  break if other_by_supporter[supporter_with_capacity[:admin_user_id]] > 4
                end

                if registration_source[0].in?(%w[therapist nursery doctor resubscribing other])
                  not_pmi_caf_or_friends[supporter_with_capacity[:admin_user_id]] ||= registration_source[0]
                  break if registration_source[0] != not_pmi_caf_or_friends[supporter_with_capacity[:admin_user_id]]
                  # not_pmi_caf_or_friends[supporter_with_capacity[:admin_user_id]] ||= []
                  # not_pmi_caf_or_friends[supporter_with_capacity[:admin_user_id]] << registration_source[0]
                  # break if not_pmi_caf_or_friends[supporter_with_capacity[:admin_user_id]].uniq.size > 2
                end

                child_support.update!(supporter_id: supporter_with_capacity[:admin_user_id])
                supporter_with_capacity[:child_supports_count] -= 1
                child_supports.delete(child_support)
              end
            end
          end
        end
      end

      # smallest_registration_sources_first

      siblings_by_supporter
    end
  end
end
