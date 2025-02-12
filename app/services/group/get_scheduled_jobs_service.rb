class Group

  class GetScheduledJobsService

    require 'sidekiq/api'
    attr_reader :scheduled_jobs

    MODULE_ZERO_FEATURE_START = DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
    GROUP_JOB_CLASS_NAMES = {
      ChildrenSupportModule::ProgramSupportModuleZeroJob.to_s => 'Programmation du module zero',
      Group::ProgramSmsToBilingualsJob.to_s => 'Programmation des messages aux familles bilingues',
      ChildrenSupportModule::ProgramFirstSupportModuleJob.to_s => 'Programmation du 1er module',
      Parent::ProgramSmsToVerifyAddressJob.to_s => 'Message de vérification des adresses',
      ChildSupport::AssignDefaultCallStatusJob.to_s => "Assignation d'un statut d'appel par défaut en cas d'absence",
      ChildSupport::AddMonthsTagJob.to_s => "Ajout des tags en fonction l'âge des enfants principaux",
      ChildrenSupportModule::FillParentsAvailableSupportModulesJob.to_s => 'Ajout des modules disponibles sur les fiches de suivi',
      ChildrenSupportModule::VerifyAvailableModulesTaskJob.to_s => 'Vérification que tous les enfants ont des modules disponibles sur leur fiche de suivi',
      ChildrenSupportModule::CreateChildrenSupportModuleJob.to_s => 'Préparation préalable au choix des parents pour l’appel 2',
      ChildrenSupportModule::SelectDefaultSupportModuleJob.to_s => 'Assignation des modules par défaut',
      ChildrenSupportModule::VerifyChosenModulesTaskJob.to_s => 'Détection des modules sans choix',
      ChildrenSupportModule::SelectModuleJob.to_s => 'Programmation des SMS de choix du module et du rappel J+3 (puis J+5 pour module 3)',
      ChildrenSupportModule::ProgramSupportModuleSmsJob.to_s => 'Programmation des SMS du module choisi',
      Group::StopSupportJob.to_s => "Arrêt de la cohorte : Fin de l'accompagnement"
    }.freeze

    def initialize(group_id)
      group = Group.find(group_id)
      @group_with_module_zero = group.with_module_zero?
      @group_id = group_id
      @module_number = group.started_at && group.started_at > MODULE_ZERO_FEATURE_START ? group.support_modules_count - 1 : group.support_modules_count
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
      format_dates

      self
    end

    private

    def add_scheduled_job(job)
      job_class_name = job.args[0]['job_class']
      job_group_id = job.args[0]['arguments']&.first
      return if job_group_id.is_a? Array

      return unless GROUP_JOB_CLASS_NAMES.key?(job_class_name) && job_group_id.to_i == @group_id.to_i

      name = if job_class_name == ChildrenSupportModule::SelectModuleJob.to_s && job.args[0]['arguments']&.third.eql?(@group_with_module_zero ? 3 : 2)
               "Programmation des SMS de choix du module aux parents n'ayant pas reçu d'appel 2"
             elsif job_class_name == ChildSupport::AssignDefaultCallStatusJob.to_s
               "Assignation d'un statut par défaut aux appels #{job.args[0]['arguments']&.second} laissés vides"
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
      @scheduled_jobs.reverse_each do |scheduled_job|
        scheduled_job[:module_number] = @module_number
        @module_number -= 1 if scheduled_job[:name] == GROUP_JOB_CLASS_NAMES[ChildrenSupportModule::FillParentsAvailableSupportModulesJob.to_s]
        scheduled_job[:module_number] = 0 if [GROUP_JOB_CLASS_NAMES[ChildrenSupportModule::ProgramSupportModuleZeroJob.to_s], GROUP_JOB_CLASS_NAMES[Group::ProgramSmsToBilingualsJob.to_s], GROUP_JOB_CLASS_NAMES[Parent::ProgramSmsToVerifyAddressJob.to_s] ].include? scheduled_job[:name]
        scheduled_job[:module_number] = 1 if scheduled_job[:name] == GROUP_JOB_CLASS_NAMES[ChildrenSupportModule::ProgramFirstSupportModuleJob.to_s]
      end
    end

    def format_dates
      @scheduled_jobs.each do |scheduled_job|
        scheduled_job[:scheduled_date] = I18n.l(scheduled_job[:scheduled_date], format: '%A %d %B %Y - %Hh%M')
      end
    end
  end
end
