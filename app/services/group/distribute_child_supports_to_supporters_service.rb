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
      @child_supports = @group.child_supports.joins(children: :source).where(children: { group_status: 'active' })
      @child_supports_with_siblings = @child_supports.group(:id).having('COUNT(child_supports.id) > 1')
      @pmi_and_caf_child_supports = @child_supports.group(:id).having('COUNT(child_supports.id) = 1').where(source: { channel: ['pmi', 'caf'] })
      @bao_and_local_partner_child_supports = @child_supports.group(:id).having('COUNT(child_supports.id) = 1').where(source: { channel: ['bao', 'local_partner'] })
      @other_sources_child_supports = @child_supports.group(:id).having('COUNT(child_supports.id) = 1').where(source: { channel: 'other' })
    end

    def call
      # use a transaction to make sure that if something goes wrong, we don't end up with a partially distributed group
      ActiveRecord::Base.transaction do
        add_supporters_capacities
        order_child_supports
        associate_child_support_to_supporters
        check_all_child_supports_are_associated
      end
    end

    private

    def add_supporters_capacities
      @child_supports_count_by_supporter.each do |count|
        count[:max_child_supports_with_siblings_count] = (@child_supports_with_siblings.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).round(0)
        count[:max_pmi_and_caf_child_supports_count] = (@pmi_and_caf_child_supports.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).round(0)
        count[:max_bao_and_local_partner_child_supports_count] = (@bao_and_local_partner_child_supports.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).round(0)
        count[:max_other_sources_child_supports_count] = (@other_sources_child_supports.pluck(:id).count.to_f * count[:child_supports_count].to_f / @child_supports.uniq.count).round(0)
      end
    end

    def order_child_supports
      @child_supports_with_siblings = @child_supports_with_siblings.to_a.sort_by { |cs| cs.current_child.source.name }
      @pmi_and_caf_child_supports = @pmi_and_caf_child_supports.to_a.sort_by { |cs| cs.current_child.source.name }
      @bao_and_local_partner_child_supports = @bao_and_local_partner_child_supports.to_a.sort_by { |cs| cs.current_child.source.name }
      @other_sources_child_supports = @other_sources_child_supports.to_a.sort_by { |cs| cs.current_child.source.name }
    end

    def associate_child_support_to_supporters
      @child_supports_count_by_supporter.each do |supporter_with_capacity|
        @child_supports_with_siblings&.shift(supporter_with_capacity[:max_child_supports_with_siblings_count])&.each do |cs|
          cs.update!(supporter_id: supporter_with_capacity[:admin_user_id])
        end
        @pmi_and_caf_child_supports&.shift(supporter_with_capacity[:max_pmi_and_caf_child_supports_count])&.each do |cs|
          cs.update!(supporter_id: supporter_with_capacity[:admin_user_id])
        end
        @bao_and_local_partner_child_supports&.shift(supporter_with_capacity[:max_bao_and_local_partner_child_supports_count])&.each do |cs|
          cs.update!(supporter_id: supporter_with_capacity[:admin_user_id])
        end
        @other_sources_child_supports&.shift(supporter_with_capacity[:max_other_sources_child_supports_count])&.each do |cs|
          cs.update!(supporter_id: supporter_with_capacity[:admin_user_id])
        end
      end
    end

    def check_all_child_supports_are_associated
      child_supports_without_supporter_count = @group.child_supports.joins(:children).where(supporter_id: nil, children: { group_status: 'active' }).count
      return if child_supports_without_supporter_count.zero?

      Rollbar.error("#{child_supports_without_supporter_count} familles n'ont pas pu être associées à une appelante. Filtrez les fiches de suivi de la cohorte sans appelante et procédez à une attribution manuelle depuis l'action groupée")
      AdminUser.all_logistics_team_members.each do |ltm|
        Task.create(
          assignee_id: ltm.id,
          title: "Toutes les fiches de suivi n'ont pas d'appelante",
          description: "#{child_supports_without_supporter_count} familles n'ont pas pu être associées à une appelante. Filtrez les fiches de suivi de la cohorte sans appelante et procédez à une attribution manuelle depuis l'action groupée",
          due_date: Time.zone.today
        )
      end
    end
  end
end
