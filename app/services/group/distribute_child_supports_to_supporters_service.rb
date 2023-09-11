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
      # use a transaction to make sure that if something goes wrong, we don't end up with a partially distributed group
      ActiveRecord::Base.transaction do
        balance_capacity_of_each_supporter
        child_supports_order_by_registration_source = order_child_supports
        associate_child_support_to_supporters(child_supports_order_by_registration_source)
        # check_all_child_supports_are_associated
      end
    end

    private

    def balance_capacity_of_each_supporter
      total_capacity = @child_supports_count_by_supporter.sum { |h| h[:child_supports_count] }
      total_child_supports_count = @group.child_supports.joins(:children).where(children: { group_status: 'active' }).uniq.count

      @child_supports_count_by_supporter.sort_by! { |child_support_count_by_supporter| child_support_count_by_supporter[:child_supports_count] }

      while total_capacity != total_child_supports_count
        @child_supports_count_by_supporter.each do |supporter_capacity|
          break if total_capacity == total_child_supports_count

          sign = total_capacity > total_child_supports_count ? -1 : 1

          supporter_capacity[:child_supports_count] += sign
          total_capacity += sign
        end
      end

      @child_supports_count_by_supporter.sort! { |first, second| second[:child_supports_count] <=> first[:child_supports_count] }
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

      child_supports_order_by_registration_source
    end

    def associate_child_support_to_supporters(child_supports_order_by_registration_source)
      # the idea is to distribute child_supports by registration_source and by land
      # we try to distribute them evenly considering 3 factors:
      # - the number of siblings distributed to a supporter
      # - the diversity of registration_source for each supporter, to avoid having a supporter with child_supports from many registration_sources
      #   while other supporters have child_supports from only one registration_source.
      # - child_supports from the registration_source 'other' are distributed evenly among supporters

      smallest_registration_sources_first = child_supports_order_by_registration_source.to_a.sort do |first, second|
        # first = [registration_source, { land => [child_supports], other_land => [child_supports] }]
        # second = [registration_source, { land => [child_supports], other_land => [child_supports] }]

        first[1].values.sum(&:size) <=> second[1].values.sum(&:size)
      end

      child_supports_with_sibling = @group.child_supports.joins(:children).where(children: { group_status: 'active' }).group(:id).having('COUNT(child_supports.id) > 1').pluck(:id)
      max_siblings_by_supporter_count = child_supports_with_sibling.count / @child_supports_count_by_supporter.count

      other_child_supports_count = child_supports_order_by_registration_source['other'].values.sum(&:size)
      max_other_child_supports_by_supporter_count = (other_child_supports_count.to_f / @child_supports_count_by_supporter.count).ceil

      other_by_supporter = {}
      not_pmi_caf_or_friends = {}
      siblings_by_supporter = {}
      @child_supports_count_by_supporter.each do |supporter_with_capacity|
        siblings_by_supporter[supporter_with_capacity[:admin_user_id]] = 0
      end

      # we do several passes to be sure all child_supports are distributed
      6.times do |index|
        break if @group.child_supports.joins(:children).where(supporter_id: nil, children: { group_status: 'active' }).count.zero?

        smallest_registration_sources_first.each do |registration_source|
          registration_source[1].each do |_land, child_supports|
            @child_supports_count_by_supporter.each do |supporter_with_capacity|
              child_supports.each do |child_support|
                break if supporter_with_capacity[:child_supports_count].zero?
                # on the first pass, we distribute only siblings to supporters
                # to be sure to distribute them evenly
                next if child_support.children.count == 1 && index < 1

                # after the first 4 passes, we stop using rules to be sure to distribute all child_supports
                if index < 4
                  # rule to distribute siblings evenly
                  if child_support.children.count > 1
                    next if siblings_by_supporter[supporter_with_capacity[:admin_user_id]] == max_siblings_by_supporter_count + (index.zero? ? 0 : 1)

                    siblings_by_supporter[supporter_with_capacity[:admin_user_id]] += 1
                  end

                  # rule to distribute child_supports from the registration_source 'other' evenly
                  if registration_source[0] == 'other'
                    other_by_supporter[supporter_with_capacity[:admin_user_id]] ||= 0
                    other_by_supporter[supporter_with_capacity[:admin_user_id]] += 1
                    break if other_by_supporter[supporter_with_capacity[:admin_user_id]] > max_other_child_supports_by_supporter_count
                  end

                  # rule to distribute child_supports from different registration_sources evenly
                  if registration_source[0].in?(%w[therapist nursery doctor resubscribing other])
                    not_pmi_caf_or_friends[supporter_with_capacity[:admin_user_id]] ||= registration_source[0]
                    break if registration_source[0] != not_pmi_caf_or_friends[supporter_with_capacity[:admin_user_id]]
                  end
                end

                child_support.update!(supporter_id: supporter_with_capacity[:admin_user_id])
                supporter_with_capacity[:child_supports_count] -= 1
                child_supports.delete(child_support)
              end
            end
          end
        end
      end
    end

    def check_all_child_supports_are_associated
      child_supports_without_supporter_count = @group.child_supports.joins(:children).where(supporter_id: nil, children: { group_status: 'active' }).count
      return if child_supports_without_supporter_count.zero?

      raise "#{child_supports_without_supporter_count} familles n'ont pas pu être associées à une appelante, l'opération est annulée, veuillez contacter le pôle technique."
    end
  end
end
