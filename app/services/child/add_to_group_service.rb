class Child

  class AddToGroupService

    LATE_SUPPORT_WARNING_MESSAGE = "1001mots : En raison d’un grand nombre de demandes, vous recevrez nos livres et conseils dans environ 2 mois. Pas d’inquiétude, c'est normal si vous avez moins de nouvelles de nous d'ici là. A bientôt!".freeze

    # Assign a child and its siblings to the right group for them
    # Depends on whether the child has siblings or not, their age and their group status

    attr_reader :group

    def initialize(child_id, at_sign_up: false)
      @child_id = child_id
      @group = nil
      @siblings = Child.find_by(id: child_id)&.siblings
      @at_sign_up = at_sign_up
    end

    def call
      return self if @siblings.nil?

      # stop all waiting siblings of 30+ months old
      # TO DO : child must have a group to have a "stopped" group_status
      # is it needed ?
      # siblings of 36+ months will be stopped later on with SelectModuleJob
      # @siblings.where(group_status: 'waiting').where('birthdate <= ?', Time.zone.today - 30.months).update(group_status: 'stopped')
      return self if @siblings.where(group_status: 'waiting').empty?

      if @siblings.count == 1
        find_group_to_single_child
      else
        find_group_to_siblings
      end
      warn_family_of_late_support if @at_sign_up
      self
    end

    private

    def find_group_to_single_child
      child = @siblings.first
      # SAME : is it needed ?
      child.update(group_status: 'stopped') and return if child.birthdate < (Time.zone.today - 30.months)
      retrieve_next_available_group(child)
      child.update(group: @group, group_status: 'active') if @group
    end

    def find_group_to_siblings
      # No siblings in active group
      if @siblings.none? { |sibling| sibling.group_status == 'active' }
        no_sibling_is_active
        return
      end

      return if @siblings.none? { |sibling| sibling.group_id }

      # At least 1 sibling is active in a group that already started
      # At the start of each module >= 2 (FillParentsAvailableSupportModulesJob), we add 6+ months old siblings to the group
      return if @siblings.any? { |sibling| sibling.group&.started? && sibling.group_status == 'active' }

      # At least 1 sibling is active but the group didn't start yet
      join_active_sibling_group
    end

    def retrieve_next_available_group(child)
      @group = child.months >= 4 ? Group.next_available_at(Time.zone.today) : Group.next_available_at(child.birthdate + 4.months)
    end

    def no_sibling_is_active
      @waiting_siblings = @siblings.where(group_status: 'waiting')
      # get oldest child less than 30 months old
      @oldest_child = @waiting_siblings.order(birthdate: :asc).first
      @group =
        if @oldest_child.months >= 4
          Group.next_available_at(Time.zone.today)
        else
          Group.next_available_at(@oldest_child.birthdate + 4.months)
        end
      return unless @group

      @waiting_siblings.each do |child|
        next if child.birthdate + 4.months > @group.started_at

        child.update(group: @group, group_status: 'active')
      end
    end

    def join_active_sibling_group
      sibling_group = @siblings.where(group_status: 'active').first.group
      @siblings.where(group_status: 'waiting').each do |child|
        next if child.birthdate + 4.months > sibling_group.started_at

        child.update(group: sibling_group, group_status: 'active')
      end
    end

  def warn_family_of_late_support
    warn_family_with_siblings
    warn_family_without_siblings
  end

  def warn_family_with_siblings
    return if @siblings.size == 1

    return unless @siblings.any? { |child| child.months < 2 } || (@siblings.any? { |child| child.group_status == 'active' } && @siblings.any? { |child| child.group_status == 'waiting' })

    send_message
  end

  def warn_family_without_siblings
    return unless @siblings.size == 1

    return unless @group.nil? || (@group && @group.started_at > 2.months.from_now)

    send_message
  end

  def send_message
    byebug
    message_service = SpotHit::SendSmsService.new([id], Time.zone.now.to_i, LATE_SUPPORT_WARNING_MESSAGE).call
    Rollbar.error("Late support warning error : #{message_service.errors}") if message_service.errors.any?
  end
  end
end
