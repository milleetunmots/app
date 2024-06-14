require 'sidekiq/api'

namespace :sidekiq do
  desc 'reschedule jobs'
  task reschedule_jobs: :environment do
    jobs = Sidekiq::ScheduledSet.new
    jobs.each do |job|
      reschedule_verify_available_modules_task_job(job)
      reschedule_verify_chosen_modules_task_job(job)
      reschedule_program_support_module_sms_job(job)
    end
  end

  def reschedule_verify_available_modules_task_job(job)
    return unless job.args[0]['job_class'] == 'ChildrenSupportModule::VerifyAvailableModulesTaskJob'

    reschedule_at_new_date(job, -4)
  end

  def reschedule_verify_chosen_modules_task_job(job)
    return unless job.args[0]['job_class'] == 'ChildrenSupportModule::VerifyChosenModulesTaskJob'

    reschedule_at_new_date(job, 1)
  end

  def reschedule_program_support_module_sms_job(job)
    return unless job.args[0]['job_class'] == 'ChildrenSupportModule::ProgramSupportModuleSmsJob'

    reschedule_at_new_date(job, -3)
  end

  def reschedule_at_new_date(job, number_of_days)
    new_date = job.at + number_of_days.days
    job.reschedule(new_date)
  end
end
