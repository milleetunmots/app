class ChildrenSupportModule

  class SelectModuleJob < ApplicationJob

    def perform(group_id, select_module_date, module_index)
      errors = {}
      group = Group.find(group_id)
      children_support_module_ids = []
      planned_date = select_module_date.sunday? ? select_module_date.next_day : select_module_date
      is_module_3 = group.with_module_zero? ? module_index.eql?(4) : module_index.eql?(3)
      is_module_2 = module_index.eql?(3)
      # stop children of 36 months+ before sending next module choice SMS
      Group::StopSupportService.new(group_id, end_of_support: false).call
      Group::AddDisengagementTagService.new(group_id, module_index).call
      ChildSupport::ChildrenDisengagementService.new(group_id).call
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
  end
end
