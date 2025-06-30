namespace :groups do
  desc 'Add support modules sent dates values to groups'
  task add_support_modules_sent_dates: :environment do
    Group.where(is_programmed: true).where.not(started_at: nil).find_each do |group|
      group.update_column(:support_module_sent_dates, {})

      update_group_support_module_sent_date(1, group.started_at, group)
      update_group_support_module_sent_date(2, group.started_at + Group::ProgramService::MODULE_ZERO_DURATION, group)

      (3..group.support_modules_count).each do |module_index|
        program_module_date = group.started_at + ((module_index - 2) * 8.weeks) + Group::ProgramService::MODULE_ZERO_DURATION
        update_group_support_module_sent_date(module_index, program_module_date, group)
      end
    end
  end

  def update_group_support_module_sent_date(module_index, date, group)
    dates = (group.support_module_sent_dates || {}).merge({ module_index => date })
    group.update_column(:support_module_sent_dates, dates)
  end
end
