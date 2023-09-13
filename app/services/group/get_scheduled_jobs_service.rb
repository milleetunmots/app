class Group

  class GetScheduledJobsService

    require 'sidekiq/api'
    attr_reader :scheduled_jobs

    MODULE_ZERO_FEATURE_START = DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
    GROUP_JOB_CLASS_NAMES = {
      'ChildrenSupportModule::ProgramSupportModuleZeroJob' => 'Programmation du module zero',
      'ChildrenSupportModule::ProgramFirstSupportModuleJob' => 'Programmation du 1er module',
      'ChildrenSupportModule::FillParentsAvailableSupportModulesJob' => 'Ajout des modules disponibles sur les fiches de suivi',
      'ChildrenSupportModule::VerifyAvailableModulesTaskJob' => 'Vérification que tous les enfants ont des modules disponibles sur leur fiche de suivi',
      'ChildrenSupportModule::CreateChildrenSupportModuleJob' => 'Préparation préalable au choix des parents pour l’appel 2',
      'ChildrenSupportModule::SelectDefaultSupportModuleJob' => 'Assignation des modules par défaut',
      'ChildrenSupportModule::VerifyChosenModulesTaskJob' => 'Détection des modules sans choix',
      'ChildrenSupportModule::CheckCreditsForGroupJob' => 'Vérification du nombre suffisant de crédits pour la programmation des modules',
      'ChildrenSupportModule::SelectModuleJob' => 'Programmation des SMS de choix du module',
      'ChildrenSupportModule::ProgramSupportModuleSmsJob' => 'Programmation des SMS du module choisi'
    }.freeze

    def initialize(group_id)
      group = Group.find(group_id)
      @group_id = group_id
      @module_number = group.started_at > MODULE_ZERO_FEATURE_START ? group.support_modules_count - 1 : group.support_modules_count
      @scheduled_jobs = []
    end

    def call
      jobs = Sidekiq::ScheduledSet.new
      jobs.each do |job|
        next unless job.args.any?

        add_scheduled_job(job)
      end
      @scheduled_jobs.sort_by! { |hash| hash[:scheduled_date] }
      set_module_numbers

      self
    end

    private

    def add_scheduled_job(job)
      job_class_name = job.args[0]['job_class']
      job_group_id = job.args[0]['arguments']&.first
      return unless GROUP_JOB_CLASS_NAMES.key?(job_class_name) && job_group_id == @group_id.to_i

      name = if job_class_name == ChildrenSupportModule::SelectModuleJob.to_s && job.args[0]['arguments']&.third.eql?(true)
               "Programmation des SMS de choix du module aux parents n'ayant pas reçu d'appel 2"
             else
               GROUP_JOB_CLASS_NAMES[job_class_name]
             end

      update_scheduled_jobs(job, name)
    end

    def update_scheduled_jobs(job, name)
      job_scheduled_date = job.at
      @scheduled_jobs << { name: name, scheduled_date: job_scheduled_date }
    end

    def set_module_numbers
      @scheduled_jobs.reverse.each do |scheduled_job|
        scheduled_job[:module_number] = @module_number
        @module_number -= 1 if scheduled_job[:name] == GROUP_JOB_CLASS_NAMES['ChildrenSupportModule::FillParentsAvailableSupportModulesJob']
        scheduled_job[:module_number] = 0 if scheduled_job[:name] == GROUP_JOB_CLASS_NAMES['ChildrenSupportModule::ProgramSupportModuleZeroJob']
        scheduled_job[:module_number] = 1 if scheduled_job[:name] == GROUP_JOB_CLASS_NAMES['ChildrenSupportModule::ProgramFirstSupportModuleJob']
      end
    end

    def set_module_numbers
      @scheduled_jobs.reverse.each do |scheduled_job|
        scheduled_job[:module_number] = @module_number
        @module_number -= 1 if scheduled_job[:name] == GROUP_JOB_CLASS_NAMES['ChildrenSupportModule::FillParentsAvailableSupportModulesJob']
        scheduled_job[:module_number] = 1 if scheduled_job[:name] == GROUP_JOB_CLASS_NAMES['ChildrenSupportModule::ProgramFirstSupportModuleJob']
      end
    end
  end
end
