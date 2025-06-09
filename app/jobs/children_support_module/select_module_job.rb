class ChildrenSupportModule

  class SelectModuleJob < ApplicationJob

    def perform(group_id, select_module_date, module_index)
      errors = {}
      group = Group.find(group_id)
      children_support_module_ids = []
      planned_date = select_module_date.sunday? ? select_module_date.next_day : select_module_date
      is_module_3 = group.with_module_zero? ? module_index.eql?(4) : module_index.eql?(3)
      is_module_2 = module_index.eql?(2)
      # stop children of 36 months+ before sending next module choice SMS
      Group::StopSupportService.new(group_id, end_of_support: false).call
      # module_index starts with 1
      # so if module_index == 3 it means this is Module 2 (that comes after Module 0 and 1)
      children = group.children.where(group_status: 'active').includes(:child_support)
      if module_index.eql?(3) && group.with_module_zero?
        children = children.where(
          child_supports: {
            call2_status: [
              I18n.t('activerecord.attributes.child_support/call_status.2_ko'),
              I18n.t('activerecord.attributes.child_support/call_status.4_dont_call'),
              I18n.t('activerecord.attributes.child_support/call_status.5_unfinished')
            ]
          }
        )
      end

      children.find_each do |child|
        unless child.child_support
          errors["child: #{child.id}"] = "Cet enfant n'a pas de fiche de suivi"
          next
        end

        next if child.siblings_on_same_group.count > 1 && child.child_support.current_child != child

        # add "estime-desengage-t1" tag to families that didn't answer any call 0->2 (if module_index = 2)
        add_t1_disengagement_tag_to_child(child) if check_t1_disengagement?(group, module_index)
        # add "estime-desengage-t2" tag to families that didn't chose module 3 & didnt answer call 3 (if module_index = 4)
        add_module4_disengagement_tag_to_child(child) if check_module4_disengagement?(group, module_index)

        child.child_support.update(
          parent1_available_support_module_list: child.child_support.parent1_available_support_module_list&.reject(&:blank?)&.first(3),
          parent2_available_support_module_list: child.child_support.parent2_available_support_module_list&.reject(&:blank?)&.first(3)
        )
        service = ChildSupport::SelectModuleService.new(
          child,
          planned_date,
          '12:30',
          module_index
        ).call
        if service.errors.any?
          errors[child.id] = service.errors
        else
          children_support_module_ids.concat(service.children_support_module_ids)
        end
      end
      reminder_date = planned_date.advance(days: is_module_2 ? 2 : 3)
      return if children_support_module_ids.empty?

      ChildrenSupportModule::CheckToSendReminderJob.set(wait_until: reminder_date.to_datetime.change(hour: 6)).perform_later(children_support_module_ids, reminder_date)
      ChildrenSupportModule::CheckToSendReminderJob.set(wait_until: (reminder_date + 2.days).to_datetime.change(hour: 6)).perform_later(children_support_module_ids, reminder_date + 2.days, true) if is_module_3
      raise errors.to_json if errors.any?
    end

    private

    def add_module4_disengagement_tag_to_child(child)
      return if [I18n.t('activerecord.attributes.child_support/call_status.1_ok'), I18n.t('activerecord.attributes.child_support/call_status.5_unfinished')].include? child.child_support.call3_status

      return if child.child_support.module3_chosen_by_parents

      child.child_support.tag_list.add('estime-desengage-t2')
      child.child_support.save!
    end

    def add_t1_disengagement_tag_to_child(child)
      family_responded_to_call_statuses = [I18n.t('activerecord.attributes.child_support/call_status.1_ok'), I18n.t('activerecord.attributes.child_support/call_status.5_unfinished')]
      return if [child.child_support.call0_status, child.child_support.call1_status, child.child_support.call2_status].any? do |status|
        status.in?(family_responded_to_call_statuses) || status.blank?
      end

      child.child_support.tag_list.add('estime-desengage-t1')
      child.child_support.save!
    end

    def check_module4_disengagement?(group, module_index)
      return true if group.id == ENV['MAY_GROUP_ID'].to_i && module_index == 4

      return true if group.id == ENV['JUNE_GROUP_ID'].to_i && module_index == 6

      (group.with_module_zero? && module_index == 5) || (!group.with_module_zero? && module_index == 4 && group.started_at > DateTime.parse(ENV['DISENGAGEMENT_FEATURE_START_DATE']))
    end

    def check_t1_disengagement?(group, module_index)
      module_index.eql?(3) && group.with_module_zero?
    end
  end
end
