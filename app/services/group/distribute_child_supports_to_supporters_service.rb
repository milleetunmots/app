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
      count_by_supporters
      child_supports
      age_ranges_child_supports_with_siblings
      age_ranges_child_supports_without_siblings
      @age_ranges_index = { '4-9' => 0, '10-16' => 1, '16-24' => 2, '24- ' => 3 }.freeze
    end

    def count_by_supporters
      @count_by_supporter_without_age_range = @count_by_supporter.select { |item| item[:age_range].nil? }.shuffle
      @count_by_supporter_with_four_to_nine_age_range = @count_by_supporter.select { |item| item[:age_range] == '4-9' }.shuffle
      @count_by_supporter_with_ten_to_fifteen_age_range = @count_by_supporter.select { |item| item[:age_range] == '10-16' }.shuffle
      @count_by_supporter_with_sixteen_to_twenty_three_age_range = @count_by_supporter.select { |item| item[:age_range] == '16-24' }.shuffle
      @count_by_supporter_with_twenty_four_and_more_age_range = @count_by_supporter.select { |item| item[:age_range] == '24- ' }.shuffle
    end

    def child_supports
      @child_supports = @group.child_supports.with_kept_children.with_a_child_in_active_group
      @child_supports_with_siblings = @child_supports.multiple_children
      @child_supports_without_siblings = @child_supports.one_child
    end

    def age_ranges_child_supports_with_siblings
      @four_to_nine_child_supports_with_siblings = @child_supports_with_siblings.where(id: @group.children.months_lt(10).map(&:child_support_id))
      @ten_to_fifteen_child_supports_with_siblings = @child_supports_with_siblings.where(id: @group.children.months_between(10, 16).map(&:child_support_id))
      @sixteen_to_twenty_three_child_supports_with_siblings = @child_supports_with_siblings.where(id: @group.children.months_between(16, 24).map(&:child_support_id))
      @twenty_four_and_more_child_supports_with_siblings = @child_supports_with_siblings.where(id: @group.children.months_gteq(24).map(&:child_support_id))
    end

    def age_ranges_child_supports_without_siblings
      @four_to_nine_child_supports_without_siblings = @child_supports_without_siblings.where(id: @group.children.months_lt(10).map(&:child_support_id))
      @ten_to_fifteen_child_supports_without_siblings = @child_supports_without_siblings.where(id: @group.children.months_between(10, 16).map(&:child_support_id))
      @sixteen_to_twenty_three_child_supports_without_siblings = @child_supports_without_siblings.where(id: @group.children.months_between(16, 24).map(&:child_support_id))
      @twenty_four_and_more_child_supports_without_siblings = @child_supports_without_siblings.where(id: @group.children.months_gteq(24).map(&:child_support_id))
    end

    def call
      # use a transaction to make sure that if something goes wrong, we don't end up with a partially distributed group
      ActiveRecord::Base.transaction do
        order_child_supports_with_siblings
        order_child_supports_without_siblings
        associate_child_supports_with_siblings_to_supporters
        associate_child_supports_without_siblings_to_supporters
        check_all_child_supports_are_associated
      end
      # @count_by_supporter.each do |count|
      #   count[:child_supports_months] = ChildSupport.in_group(@group.id).where(supporter_id: count[:admin_user_id]).map { |cs| cs.children.map(&:months) }.flatten
      #   count[:current_child_supports_months] = ChildSupport.in_group(@group.id).where(supporter_id: count[:admin_user_id]).map { |cs| cs.current_child.months }.flatten
      # end
      # @count_by_supporter.each do |count|
      #   p "Id #{count[:admin_user_id]}"
      #   p "Capacity #{count[:child_supports_count]}"
      #   p "Age range #{count[:age_range]}"
      #   p "Months #{count[:child_supports_months]}"
      #   p "Current child months #{count[:current_child_supports_months]}"
      #   p "#################################################"
      # end
      Rollbar.info('Attribution des accompagnantes terminée')
    end

    private

    def order_child_supports_with_siblings
      @four_to_nine_child_supports_with_siblings = @four_to_nine_child_supports_with_siblings.to_a.sort_by { |cs| cs.current_child.months }
      @ten_to_fifteen_child_supports_with_siblings = @ten_to_fifteen_child_supports_with_siblings.to_a.sort_by { |cs| cs.current_child.months }
      @sixteen_to_twenty_three_child_supports_with_siblings = @sixteen_to_twenty_three_child_supports_with_siblings.to_a.sort_by { |cs| cs.current_child.months }
      @twenty_four_and_more_child_supports_with_siblings = @twenty_four_and_more_child_supports_with_siblings.to_a.shuffle
      @child_supports_with_siblings_array = [@four_to_nine_child_supports_with_siblings, @ten_to_fifteen_child_supports_with_siblings, @sixteen_to_twenty_three_child_supports_with_siblings, @twenty_four_and_more_child_supports_with_siblings]
    end

    def order_child_supports_without_siblings
      @four_to_nine_child_supports_without_siblings = @four_to_nine_child_supports_without_siblings.to_a.sort_by { |cs| cs.current_child.months }
      @ten_to_fifteen_child_supports_without_siblings = @ten_to_fifteen_child_supports_without_siblings.to_a.sort_by { |cs| cs.current_child.months }
      @sixteen_to_twenty_three_child_supports_without_siblings = @sixteen_to_twenty_three_child_supports_without_siblings.to_a.sort_by { |cs| cs.current_child.months }
      @twenty_four_and_more_child_supports_without_siblings = @twenty_four_and_more_child_supports_without_siblings.to_a.shuffle
      @child_supports_without_siblings_array = [@four_to_nine_child_supports_without_siblings, @ten_to_fifteen_child_supports_without_siblings, @sixteen_to_twenty_three_child_supports_without_siblings, @twenty_four_and_more_child_supports_without_siblings]
    end

    def update_child_supports_to_assign_to_supporter(capacity, age_range, child_supports_array)
      @child_supports_to_assign = []
      child_supports_array.each_with_index do |child_supports, index|
        next if index < @age_ranges_index[age_range]

        @child_supports_to_assign += child_supports.shift(capacity)
        break if child_supports.size < capacity
      end
    end

    def assign_child_supports(child_supports, index, capacity)
      return unless child_supports

      child_supports.shift(capacity).each do |cs|
        next if @count_by_supporter[index][:admin_user_id].nil?

        break if enough_child_support?(@count_by_supporter[index])

        next if cs.supporter_id.present?

        next unless cs.update!(supporter_id: @count_by_supporter[index][:admin_user_id])

        @count_by_supporter[index][:assigned_child_supports_count] += 1
      end
    end

    def enough_child_support?(supporter_with_capacity)
      supporter_with_capacity[:assigned_child_supports_count] >= supporter_with_capacity[:child_supports_count]
    end

    def associate_child_supports_with_siblings_to_supporters
      child_supports_with_siblings_count = @child_supports_with_siblings.to_a.size.to_f
      assign_child_supports_with_siblings_to_supporters_with_age_range(child_supports_with_siblings_count)
      assign_child_supports_with_siblings_to_supporters_without_age_range(child_supports_with_siblings_count)
      assign_child_supports_with_siblings_left_over
    end

    def assign_child_supports_with_siblings_to_supporters_with_age_range(child_supports_with_siblings_count)
      [
        @count_by_supporter_with_four_to_nine_age_range,
        @count_by_supporter_with_ten_to_fifteen_age_range,
        @count_by_supporter_with_sixteen_to_twenty_three_age_range,
        @count_by_supporter_with_twenty_four_and_more_age_range
      ].each do |count_by_supporter|
        count_by_supporter.each do |count|
          next if count[:admin_user_id].nil?

          index = @count_by_supporter.index(count)
          @count_by_supporter[index][:max_child_supports_with_siblings_count] = (child_supports_with_siblings_count * count[:child_supports_count].to_f / @child_supports.count).floor
          update_child_supports_to_assign_to_supporter(count[:max_child_supports_with_siblings_count], count[:age_range], @child_supports_with_siblings_array)
          assign_child_supports(@child_supports_to_assign, index, @count_by_supporter[index][:max_child_supports_with_siblings_count])
        end
      end
    end

    def assign_child_supports_with_siblings_to_supporters_without_age_range(child_supports_with_siblings_count)
      @child_supports_with_siblings = @child_supports_with_siblings.where(supporter_id: nil)
      @twenty_four_and_more_child_supports_with_siblings = @child_supports_with_siblings.where(id: @group.children.months_gteq(24).map(&:child_support_id)).to_a.shuffle
      @lt_twenty_four_child_supports_with_siblings = @child_supports_with_siblings.where.not(id: @twenty_four_and_more_child_supports_with_siblings.pluck(:id)).to_a.sort_by { |cs| cs.current_child.months }
      @count_by_supporter_without_age_range.each do |count|
        next if count[:admin_user_id].nil?

        index = @count_by_supporter.index(count)
        @count_by_supporter[index][:max_child_supports_with_siblings_count] = (child_supports_with_siblings_count * count[:child_supports_count].to_f / @child_supports.count).floor
        assign_child_supports(@lt_twenty_four_child_supports_with_siblings, index, @count_by_supporter[index][:max_child_supports_with_siblings_count])
      end
      @count_by_supporter_without_age_range.each do |count|
        next if count[:admin_user_id].nil?

        index = @count_by_supporter.index(count)
        @count_by_supporter[index][:max_child_supports_with_siblings_count] = (child_supports_with_siblings_count * count[:child_supports_count].to_f / @child_supports.count).floor
        assign_child_supports(@twenty_four_and_more_child_supports_with_siblings, index, @count_by_supporter[index][:max_child_supports_with_siblings_count])
      end
    end

    def assign_child_supports_with_siblings_left_over
      @child_supports_with_siblings = @child_supports_with_siblings.select { |cs| cs.supporter_id.nil? }.sort_by { |cs| cs.current_child.months }
      while @child_supports_with_siblings.any?
        @count_by_supporter.each do |supporter_with_capacity|
          next if supporter_with_capacity[:admin_user_id].nil?

          break if @child_supports_with_siblings.empty?

          child_support = @child_supports_with_siblings.shift
          supporter_with_capacity[:assigned_child_supports_count] += 1 if child_support.update!(supporter_id: supporter_with_capacity[:admin_user_id])
        end
      end
    end

    def associate_child_supports_without_siblings_to_supporters
      assign_child_supports_without_siblings_to_supporters_with_age_range
      assign_child_supports_without_siblings_to_supporters_without_age_range
      assign_child_supports_without_siblings_left_over
    end

    def assign_child_supports_without_siblings_to_supporters_with_age_range
      [
        @count_by_supporter_with_four_to_nine_age_range,
        @count_by_supporter_with_ten_to_fifteen_age_range,
        @count_by_supporter_with_sixteen_to_twenty_three_age_range,
        @count_by_supporter_with_twenty_four_and_more_age_range
      ].each do |count_by_supporter|
        count_by_supporter.each do |count|
          next if count[:admin_user_id].nil?

          index = @count_by_supporter.index(count)
          capacity = count[:child_supports_count] - count[:assigned_child_supports_count]
          update_child_supports_to_assign_to_supporter(capacity, count[:age_range], @child_supports_without_siblings_array)
          assign_child_supports(@child_supports_to_assign, index, capacity)
        end
      end
    end

    def assign_child_supports_without_siblings_to_supporters_without_age_range
      @child_supports_without_siblings = @child_supports_without_siblings.where(supporter_id: nil)
      @twenty_four_and_more_child_supports_without_siblings = @child_supports_without_siblings.where(id: @group.children.months_gteq(24).map(&:child_support_id)).to_a.shuffle
      @lt_twenty_four_child_supports_without_siblings = @child_supports_without_siblings.where.not(id: @twenty_four_and_more_child_supports_without_siblings.pluck(:id)).to_a.sort_by { |cs| cs.current_child.months }
      @count_by_supporter_without_age_range.each do |count|
        next if count[:admin_user_id].nil?

        index = @count_by_supporter.index(count)
        capacity = count[:child_supports_count] - count[:assigned_child_supports_count]
        assign_child_supports(@lt_twenty_four_child_supports_without_siblings, index, capacity)
      end
      @count_by_supporter_without_age_range.each do |count|
        next if count[:admin_user_id].nil?

        index = @count_by_supporter.index(count)
        capacity = count[:child_supports_count] - count[:assigned_child_supports_count]
        assign_child_supports(@twenty_four_and_more_child_supports_without_siblings, index, capacity)
      end
    end

    def assign_child_supports_without_siblings_left_over
      @child_supports_without_siblings = @child_supports_without_siblings.select { |cs| cs.supporter_id.nil? }.sort_by { |cs| cs.current_child.months }
      while @child_supports_without_siblings.any?
        @count_by_supporter.each do |supporter_with_capacity|
          next if supporter_with_capacity[:admin_user_id].nil?

          break if @child_supports_without_siblings.empty?

          child_support = @child_supports_without_siblings.shift
          supporter_with_capacity[:assigned_child_supports_count] += 1 if child_support.update!(supporter_id: supporter_with_capacity[:admin_user_id])
        end
      end
    end

    def check_all_child_supports_are_associated
      child_supports_without_supporter = ChildSupport.groups_in(@group.id).with_a_child_in_active_group.without_supporter.to_a
      return if child_supports_without_supporter.empty?

      @count_by_supporter.shuffle!
      while child_supports_without_supporter.any?
        @count_by_supporter.each do |supporter_with_capacity|
          break if child_supports_without_supporter.empty?

          child_support = child_supports_without_supporter.shift
          child_support.update!(supporter_id: supporter_with_capacity[:admin_user_id])
        end
      end

      Rollbar.error("#{child_supports_without_supporter.count} familles n'ont pas pu être associées à une accompagnante. Filtrez les fiches de suivi de la cohorte sans accompagnante et procédez à une attribution manuelle depuis l'action groupée")
      Task::CreateAutomaticTaskService.new(
        title: "Toutes les fiches de suivi n'ont pas d'accompagnante",
        description: "#{child_supports_without_supporter.count} familles n'ont pas pu être associées à une accompagnante. Filtrez les fiches de suivi de la cohorte sans accompagnante et procédez à une attribution manuelle depuis l'action groupée"
      ).call
    end
  end
end
