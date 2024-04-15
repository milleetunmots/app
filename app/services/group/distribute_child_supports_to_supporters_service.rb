class Group

  class DistributeChildSupportsToSupportersService

    # count_by_supporter = [
    #   { admin_user_id: 85, child_supports_count: 15, age_range: '4-9', assigned_child_supports_count: 0 },
    #   { admin_user_id: 110, child_supports_count: 10, age_range: nil, assigned_child_supports_count: 0 },
    #   ...
    # ]
    def initialize(group, count_by_supporter)
      @group = group
      @count_by_supporter = count_by_supporter
      @count_by_supporter_without_age_range = @count_by_supporter.select { |item| item[:age_range].nil? }.shuffle
      @count_by_supporter_with_four_to_nine_age_range = @count_by_supporter.select { |item| item[:age_range] == '4-9' }.shuffle
      @count_by_supporter_with_ten_to_fifteen_age_range = @count_by_supporter.select { |item| item[:age_range] == '10-16' }.shuffle
      @count_by_supporter_with_sixteen_to_twenty_three_age_range = @count_by_supporter.select { |item| item[:age_range] == '16-24' }.shuffle
      @count_by_supporter_with_twenty_four_and_more_age_range = @count_by_supporter.select { |item| item[:age_range] == '24- ' }.shuffle
      @child_supports = @group.child_supports.with_a_child_in_active_group
      @child_supports_with_siblings = @child_supports.multiple_children
      @child_supports_without_siblings = @child_supports.one_child
      @four_to_nine_child_supports = @child_supports_without_siblings.where(id: Child.months_between(4, 10).map(&:child_support_id))
      @ten_to_fifteen_child_supports = @child_supports_without_siblings.where(id: Child.months_between(10, 16).map(&:child_support_id))
      @sixteen_to_twenty_three_child_supports = @child_supports_without_siblings.where(id: Child.months_between(16, 24).map(&:child_support_id))
      @twenty_four_and_more_child_supports = @child_supports_without_siblings.where(id: Child.months_gteq(24).map(&:child_support_id))
      @age_ranges_index = { '4-9' => 0, '10-16' => 1, '16-24' => 2, '24- ' => 3 }.freeze
    end

    def call
      # use a transaction to make sure that if something goes wrong, we don't end up with a partially distributed group
      ActiveRecord::Base.transaction do
        balance_capacity_of_each_supporter
        order_child_supports
        associate_child_supports_with_siblings_to_supporters
        associate_child_supports_without_siblings_to_supporters
        check_all_child_supports_are_associated
      end
    end

    private

    def balance_capacity_of_each_supporter
      total_capacity = @count_by_supporter.sum { |h| h[:child_supports_count] }
      total_child_supports_count = @child_supports.uniq.count

      @count_by_supporter.shuffle!

      proportion_factor = total_child_supports_count.to_f / total_capacity
      @count_by_supporter.each do |supporter_capacity|
        supporter_capacity[:child_supports_count] = (supporter_capacity[:child_supports_count] * proportion_factor).round
      end
    end

    def order_child_supports
      @child_supports_with_siblings = @child_supports_with_siblings.to_a.sort_by { |cs| cs.current_child.months }
      @four_to_nine_child_supports = @four_to_nine_child_supports.to_a.sort_by { |cs| cs.current_child.months }
      @ten_to_fifteen_child_supports = @ten_to_fifteen_child_supports.to_a.sort_by { |cs| cs.current_child.months }
      @sixteen_to_twenty_three_child_supports = @sixteen_to_twenty_three_child_supports.to_a.sort_by { |cs| cs.current_child.months }
      @twenty_four_and_more_child_supports = @twenty_four_and_more_child_supports.to_a.sort_by { |cs| cs.current_child.months }
      @child_supports_array = [@four_to_nine_child_supports, @ten_to_fifteen_child_supports, @sixteen_to_twenty_three_child_supports, @twenty_four_and_more_child_supports]
    end

    def associate_child_supports_with_siblings_to_supporters
      @count_by_supporter.each do |count|
        count[:max_child_supports_with_siblings_count] = [count[:child_supports_count].to_i, (@child_supports_with_siblings.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).ceil + 1].min
        assign_child_supports(@child_supports_with_siblings, count, count[:max_child_supports_with_siblings_count])
      end
    end

    def assign_child_supports(child_supports, supporter_with_capacity, max_child_supports_count)
      return unless child_supports

      child_supports.shift(max_child_supports_count).each do |cs|
        break if enough_child_support?(supporter_with_capacity)

        supporter_with_capacity[:assigned_child_supports_count] += 1 if cs.update!(supporter_id: supporter_with_capacity[:admin_user_id])
      end
    end

    def enough_child_support?(supporter_with_capacity)
      supporter_with_capacity[:assigned_child_supports_count] >= supporter_with_capacity[:child_supports_count]
    end

    def associate_child_supports_without_siblings_to_supporters
      [
        @count_by_supporter_with_four_to_nine_age_range,
        @count_by_supporter_with_ten_to_fifteen_age_range,
        @count_by_supporter_with_sixteen_to_twenty_three_age_range,
        @count_by_supporter_with_twenty_four_and_more_age_range
      ].each do |count_by_supporter|
        count_by_supporter.each do |count|
          capacity = count[:child_supports_count] - count[:max_child_supports_with_siblings_count]
          update_child_supports_to_assign_to_supporter(capacity, count[:age_range])
          assign_child_supports(@child_supports_to_assign, count, capacity)
        end
      end
      @child_supports_without_siblings = @child_supports_without_siblings.where(supporter_id: nil).to_a.sort_by { |cs| cs.current_child.months }
      @count_by_supporter_without_age_range.each do |count|
        capacity = count[:child_supports_count] - count[:max_child_supports_with_siblings_count]
        assign_child_supports(@child_supports_without_siblings, count, capacity)
      end
    end

    def update_child_supports_to_assign_to_supporter(capacity, age_range)
      @child_supports_to_assign = []
      @child_supports_array.each_with_index do |child_supports, index|
        next if index < @age_ranges_index[age_range]

        @child_supports_to_assign += child_supports.shift(capacity)
        break if child_supports.size < capacity
      end
    end

    def assign_child_supports(child_supports, supporter_with_capacity, max_child_supports_count)
      return unless child_supports

      child_supports.shift(max_child_supports_count).each do |cs|
        break if enough_child_support?(supporter_with_capacity)

        supporter_with_capacity[:assigned_child_supports_count] += 1 if cs.update!(supporter_id: supporter_with_capacity[:admin_user_id])
      end
    end

    def check_all_child_supports_are_associated
      child_supports_without_supporter = ChildSupport.groups_in(@group.id).with_a_child_in_active_group.without_supporter.to_a
      return if child_supports_without_supporter.count.zero?

      @count_by_supporter.each do |supporter_with_capacity|
        next if enough_child_support?(supporter_with_capacity)

        assign_child_supports(child_supports_without_supporter, supporter_with_capacity, supporter_with_capacity[:child_supports_count] - supporter_with_capacity[:assigned_child_supports_count])
      end

      Rollbar.error("#{child_supports_without_supporter.count} familles n'ont pas pu être associées à une appelante. Filtrez les fiches de suivi de la cohorte sans appelante et procédez à une attribution manuelle depuis l'action groupée")
      AdminUser.all_logistics_team_members.each do |ltm|
        Task.create(
          assignee_id: ltm.id,
          title: "Toutes les fiches de suivi n'ont pas d'appelante",
          description: "#{child_supports_without_supporter.count} familles n'ont pas pu être associées à une appelante. Filtrez les fiches de suivi de la cohorte sans appelante et procédez à une attribution manuelle depuis l'action groupée",
          due_date: Time.zone.today
        )
      end
    end
  end
end
