task :add_modules_to_group, %i[group_id modules_number] => :environment do |_, args|
  group = Group.find(args[:group_id])
  modules_number = args[:modules_number].to_i
  date = group.started_at

  MODULE_ZERO_DURATION = 4.weeks.freeze

  ((group.support_modules_count + 1)..(group.support_modules_count + modules_number)).each do |module_index|
    fill_parents_available_support_modules_date = date + ((module_index - 2) * 8.weeks) - 6.weeks + MODULE_ZERO_DURATION
    available_module_list_verification_date = date + ((module_index - 2) * 8.weeks) - 5.weeks + MODULE_ZERO_DURATION
    select_module_date = (date + ((module_index - 2) * 8.weeks) - 4.weeks).next_occurring(:saturday) + MODULE_ZERO_DURATION
    defaul_support_module_selection_date = date + ((module_index - 2) * 8.weeks) - 2.weeks - 1.day + MODULE_ZERO_DURATION
    chosen_modules_verification_date = date + ((module_index - 2) * 8.weeks) - 2.weeks + MODULE_ZERO_DURATION
    check_spothit_credits_date = date + ((module_index - 2) * 8.weeks) - 1.week + MODULE_ZERO_DURATION
    program_support_module_date = date + ((module_index - 2) * 8.weeks) + MODULE_ZERO_DURATION

    byebug

    ChildrenSupportModule::FillParentsAvailableSupportModulesJob.set(wait_until: fill_parents_available_support_modules_date.to_datetime.change(hour: 6)).perform_later(args[:group_id], false)
    ChildrenSupportModule::VerifyAvailableModulesTaskJob.set(wait_until: available_module_list_verification_date.to_datetime.change(hour: 6)).perform_later(args[:group_id])
    ChildrenSupportModule::SelectModuleJob.set(wait_until: select_module_date.to_datetime.change(hour: 6)).perform_later(args[:group_id], select_module_date, module_index)
    ChildrenSupportModule::SelectDefaultSupportModuleJob.set(wait_until: defaul_support_module_selection_date.to_datetime.change(hour: 6)).perform_later(args[:group_id])
    ChildrenSupportModule::VerifyChosenModulesTaskJob.set(wait_until: chosen_modules_verification_date.to_datetime.change(hour: 6)).perform_later(args[:group_id])
    ChildrenSupportModule::CheckCreditsForGroupJob.set(wait_until: check_spothit_credits_date.to_datetime.change(hour: 6)).perform_later(args[:group_id])
    ChildrenSupportModule::ProgramSupportModuleSmsJob.set(wait_until: program_support_module_date.to_datetime.change(hour: 6)).perform_later(args[:group_id], program_support_module_date)
  end

  group.support_modules_count += modules_number
  group.save

  end_support_date = date + ((group.support_modules_count - 2) * 8.weeks) + 4.weeks + MODULE_ZERO_DURATION
  Group::StopSupportJob.set(wait_until: end_support_date.to_datetime.change(hour: 6)).perform_later(args[:group_id])
end
