class Group

  class DistributeChildSupportsToSupportersService

    # child_supports_count_by_supporter = [
    #   { admin_user_id: 85, child_supports_count: 15 },
    #   { admin_user_id: 110, child_supports_count: 10 },
    #   ...
    # ]
    def initialize(group, child_supports_count_by_supporter)
      @group = group
      @child_supports_count_by_supporter = child_supports_count_by_supporter
      @child_supports = @group.child_supports.with_a_child_in_active_group
      @child_supports_with_source = @child_supports.joins(children: :source)
      @child_supports_with_siblings = @child_supports_with_source.group(:id).having('COUNT(child_supports.id) > 1')
      @pmi_and_caf_child_supports = @child_supports_with_source.group(:id).having('COUNT(child_supports.id) = 1').where(source: { channel: ['pmi', 'caf'] })
      @bao_and_local_partner_child_supports = @child_supports_with_source.group(:id).having('COUNT(child_supports.id) = 1').where(source: { channel: ['bao', 'local_partner'] })
      @other_sources_child_supports = @child_supports_with_source.group(:id).having('COUNT(child_supports.id) = 1').where(source: { channel: 'other' })
      @child_supports_without_source = @child_supports.where.not(id: @child_supports_with_source.ids)
      @other_or_missing_sources_child_supports = ChildSupport.where(id: [@other_sources_child_supports.ids + @child_supports_without_source.ids].uniq)
    end

    def call
      # use a transaction to make sure that if something goes wrong, we don't end up with a partially distributed group
      ActiveRecord::Base.transaction do
        balance_capacity_of_each_supporter
        add_supporters_capacities
        order_child_supports
        associate_child_support_to_supporters
        check_all_child_supports_are_associated
      end
    end

    private

    def balance_capacity_of_each_supporter
      total_capacity = @child_supports_count_by_supporter.sum { |h| h[:child_supports_count] }
      total_child_supports_count = @child_supports.uniq.count

      @child_supports_count_by_supporter.shuffle!

      proportion_factor = total_child_supports_count.to_f / total_capacity
      @child_supports_count_by_supporter.each do |supporter_capacity|
        supporter_capacity[:child_supports_count] = (supporter_capacity[:child_supports_count] * proportion_factor).round
      end
    end

    def add_supporters_capacities
      @child_supports_count_by_supporter.each do |count|
        count[:max_child_supports_with_siblings_count] = (@child_supports_with_siblings.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).ceil
        count[:max_pmi_and_caf_child_supports_count] = (@pmi_and_caf_child_supports.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).ceil
        count[:max_bao_and_local_partner_child_supports_count] = (@bao_and_local_partner_child_supports.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).ceil
        count[:max_other_sources_child_supports_count] = (@other_or_missing_sources_child_supports.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).ceil
      end
    end

    def order_child_supports
      @child_supports_with_siblings = @child_supports_with_siblings.to_a.sort_by { |cs| cs.current_child.source.name }
      @pmi_and_caf_child_supports = @pmi_and_caf_child_supports.to_a.sort_by { |cs| cs.current_child.source.name }
      @bao_and_local_partner_child_supports = @bao_and_local_partner_child_supports.to_a.sort_by { |cs| cs.current_child.source.name }
      @other_or_missing_sources_child_supports = @other_or_missing_sources_child_supports.to_a.sort_by { |cs| cs.current_child.source&.name }
    end

    def enough_child_support?(supporter_with_capacity)
      supporter_with_capacity[:assigned_child_supports_count] >= supporter_with_capacity[:child_supports_count]
    end

    def assign_child_supports(child_supports, supporter_with_capacity, max_child_supports_count)
      return unless child_supports

      child_supports.shift(max_child_supports_count).each do |cs|
        break if enough_child_support?(supporter_with_capacity)

        supporter_with_capacity[:assigned_child_supports_count] += 1 if cs.update!(supporter_id: supporter_with_capacity[:admin_user_id])
      end
    end

    def associate_child_support_to_supporters
      child_support_sources = [
        { supports: @child_supports_with_siblings, max_count: :max_child_supports_with_siblings_count },
        { supports: @other_or_missing_sources_child_supports, max_count: :max_other_sources_child_supports_count },
        { supports: @pmi_and_caf_child_supports, max_count: :max_pmi_and_caf_child_supports_count },
        { supports: @bao_and_local_partner_child_supports, max_count: :max_bao_and_local_partner_child_supports_count }
      ]
      # order from smallest to biggest count to avoid maxing a supporter quota before all sources types could be assigned
      random_supporter_with_capacity = @child_supports_count_by_supporter.first
      child_support_sources.sort_by! { |source| random_supporter_with_capacity[source[:max_count]] }
      @child_supports_count_by_supporter.each do |supporter_with_capacity|
        supporter_with_capacity[:assigned_child_supports_count] = 0
        child_support_sources.each do |source|
          assign_child_supports(source[:supports], supporter_with_capacity, supporter_with_capacity[source[:max_count]])
          break if enough_child_support?(supporter_with_capacity)
        end
      end
    end

    def check_all_child_supports_are_associated
      child_supports_without_supporter = ChildSupport.groups_in(@group.id).with_a_child_in_active_group.without_supporter.to_a
      return if child_supports_without_supporter.count.zero?

      @child_supports_count_by_supporter.each do |supporter_with_capacity|
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
