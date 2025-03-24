ActiveAdmin.register Group do
  decorate_with GroupDecorator

  has_better_csv
  has_paper_trail
  # has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :children
    column :started_at
    column :ended_at
    column :support_modules_count
    column :is_programmed
    column :support_module_programmed
    column :expected_children_number
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item(*args)
      end
    end
  end

  filter :name
  filter :started_at
  filter :ended_at
  filter :group_active,
          as: :check_boxes,
          label: '',
          collection: proc { [['Cohorte en cours', 'active']] }
  filter :group_ended,
          as: :check_boxes,
          label: '',
          collection: proc { [['Cohorte finie', 'ended']] }
  filter :next_group,
          as: :check_boxes,
          label: '',
          collection: proc { [['Cohorte future', 'next']] }
  filter :support_modules_count
  filter :is_programmed
  filter :expected_children_number
  filter :is_excluded_from_analytics
  filter :enable_calls_recording
  filter :created_at
  filter :updated_at

  scope :all, default: true
  scope :not_ended
  scope :ended
  scope(I18n.t('activerecord.attributes.group.is_excluded_from_analytics')) do |scope|
    scope.merge(Group.excluded_from_analytics)
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :is_excluded_from_analytics
      f.input :enable_calls_recording
      f.input :name
      f.input :started_at, as: :datepicker
      f.input :ended_at, as: :datepicker
      f.input :support_modules_count
      f.input :expected_children_number, hint: "Il n'y aura plus d'assignation automatique d'enfant à l'inscription une fois ce nombre atteint. Mettre à 0 pour empêcher les assignations automatiques."
      unless f.object.new_record?
        inputs "Sessions d'appels" do
          f.input :call0_start_date, as: :datepicker
          f.input :call0_end_date, as: :datepicker
          f.input :call1_start_date, as: :datepicker
          f.input :call1_end_date, as: :datepicker
          f.input :call2_start_date, as: :datepicker
          f.input :call2_end_date, as: :datepicker
          f.input :call3_start_date, as: :datepicker
          f.input :call3_end_date, as: :datepicker
        end
      end
    end
    f.actions
  end

  permit_params :name, :started_at, :ended_at, :support_modules_count, :expected_children_number, :enable_calls_recording, :is_excluded_from_analytics,
    :call0_start_date, :call0_end_date, :call1_start_date, :call1_end_date, :call2_start_date, :call2_end_date, :call3_start_date,
    :call3_end_date

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    tabs do
      tab I18n.t('group.base') do
        attributes_table do
          row :is_excluded_from_analytics
          row :name
          row :children
          row :families
          row :started_at
          row :ended_at
          row :support_modules_count
          row :support_module_programmed
          row :expected_children_number
          row :enable_calls_recording
          row :is_programmed
          row :call0_start_date
          row :call0_end_date
          row :call1_start_date
          row :call1_end_date
          row :call2_start_date
          row :call2_end_date
          row :call3_start_date
          row :call3_end_date
        end
      end
      tab I18n.t('group.supporters') do
        panel I18n.t('group.panel_supporters_title') do
          table_for resource.supporters.distinct.order(:name) do
            column I18n.t('group.supporter_name') do |supporter|
              link_to supporter.name, [:admin, supporter]
            end
            column I18n.t('group.supporter_child_supports_count') do |supporter|
              link_to supporter.child_supports.joins(:children).where(children: { group_id: resource.id }).uniq.size,
                      [:admin, :child_supports, { q: { group_id_in: [resource.id], supporter_id_in: [supporter.id] } }]
            end
            column I18n.t('group.supporter_children_count') do |supporter|
              link_to supporter.children.where(group_id: resource.id).size, [:admin, :children, { q: { group_id_in: [resource.id], supporter_id_in: [supporter.id] } }]
            end
          end
        end
      end
      tab I18n.t('group.scheduled_jobs') do
        panel I18n.t('group.panel_scheduled_jobs') do
          render 'admin/groups/group_scheduled_jobs', scheduled_jobs_group_by_module_number: Group::GetScheduledJobsService.new(resource.id).call.scheduled_jobs.group_by { |job|
                                                                                               job[:module_number]
                                                                                             }
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # MEMBER ACTIONS
  # ---------------------------------------------------------------------------

  action_item :program, only: :show, if: proc { !resource.is_programmed } do
    link_to I18n.t('group.program_link'), [:program, :admin, resource]
  end

  member_action :program do
    service = Group::ProgramService.new(resource.object).call

    if service.errors.empty?
      redirect_to [:admin, resource], notice: 'Les futures tâches, envois de SMS ont été programmés avec succès.'
    else
      flash[:alert] = service.errors
      redirect_to [:admin, resource]
    end
  end

  action_item :export, only: :show do
    link_to I18n.t('group.export_link'), [:export, :admin, resource]
  end

  member_action :export do
    service = Child::ExportBooksV2Service.new(group_ids: [resource.id]).call

    if service.errors.empty?
      send_file service.zip_file.path, type: 'application/zip', x_sendfile: true,
                                       disposition: 'attachment', filename: "#{Time.zone.today.strftime('%d-%m-%Y')}.zip"
    else
      flash[:alert] = service.errors
      redirect_back(fallback_location: root_path)
    end
  end

  action_item :distribute_child_support, only: :show do
    link_to I18n.t('group.distribute_child_support'), %i[distribute_child_supports admin group]
  end

  member_action :distribute_child_supports do
    @perform_action = perform_distribute_child_support_admin_group_path
    @calls = Airtables::Call.all_call_missions
  end

  member_action :perform_distribute_child_support, method: :post do
    message = "La répartition des accompagnantes est en cours. Cela peut prendre plusieurs minutes, merci de patienter."
    name = params[:group][:name]
    child_supports_count_by_supporter = Airtables::Call.call_missions_by_name(name).map do |call_mission|
      {
        admin_user_id: Airtables::Caller.caller_id_by_airtable_caller_id(call_mission.airtable_caller_id),
        supporter_name: call_mission['Name'].split(' - #').first,
        child_supports_count: call_mission.child_supports_count,
        age_range: call_mission.age_range,
        assigned_child_supports_count: 0
    }
    end
    supporters_without_id = child_supports_count_by_supporter.select { |supporter_count| supporter_count[:admin_user_id].nil? }.map { |sc| sc[:supporter_name] }
    supporters_without_child_supports_count = child_supports_count_by_supporter.select { |supporter_count| supporter_count[:child_supports_count].nil? }.map { |sc| sc[:supporter_name] }
    total_capacity = child_supports_count_by_supporter.sum { |supporter_count| supporter_count[:child_supports_count] } if supporters_without_child_supports_count.empty?
    families_count = resource.model.child_supports.with_kept_children.with_a_child_in_active_group.count
    if supporters_without_id.empty? && supporters_without_child_supports_count.empty? && total_capacity == families_count
      Group::DistributeChildSupportsToSupportersJob.perform_later(resource.model, child_supports_count_by_supporter)
      redirect_to admin_group_path, notice: message
    else
      message = "Sur airtable, le N° suivi base de ces accompagnantes n'est pas indiqué : #{supporters_without_id.join(', ')}" unless supporters_without_id.empty?
      message = "Sur airtable, le Nb de familles de ces accompagnantes n'est pas indiqué : #{supporters_without_child_supports_count.join(', ')}" unless supporters_without_child_supports_count.empty?
      message = "Le nombre total d'enfants prévus sur airtable ne correspond pas au nombre de familles dans la base avec au moins un enfant actif dans cette cohorte." unless total_capacity == families_count
      redirect_to admin_group_path, alert: message
    end
  end

  action_item :children_support_modules_informations, only: :show do
    if resource.model.support_module_programmed.positive?
      group_without_module_zero = resource.model.started_at < DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
      dropdown_menu 'Récupérer les informations des modules choisis' do
        (0..resource.model.support_modules_count).each do |index|
          next if index.zero? && group_without_module_zero

          ajusted_index = group_without_module_zero ? index - 1 : index
          current_module = ajusted_index == resource.model.support_module_programmed
          not_programmed = ajusted_index >= resource.model.support_module_programmed
          item_text = "Module #{index} #{'- en cours de programmation' if current_module}#{'- à venir' if not_programmed && !current_module}"
          item item_text, children_support_modules_informations_admin_group_path(index: group_without_module_zero ? index : index + 1)
        end
      end
    end
  end

  member_action :children_support_modules_informations do
    index = params[:index]
    service = Group::ChildrenSupportModulesInformationsService.new(resource.id, index).call
    send_file(
      service.zip_file.path,
      type: 'application/zip',
      x_sendfile: true,
      disposition: 'attachment',
      filename: service.zip_filename
    )
  end

  batch_action :support_modules_chosen_excel_export do |ids|
    ids.each do |group_id|
      group = Group.find(group_id)
      if ChildrenSupportModule.where(child_id: group.active_children_ids, is_programmed: false).where.not(support_module_id: nil).count.zero?
        flash[:alert] = "Les modules de la cohorte #{group.name} ont déjà été programmés"
        break
      end
      if ChildrenSupportModule.exists?(child_id: group.active_children_ids, is_programmed: false, support_module_id: nil)
        flash[:alert] = "Dans la cohorte #{group.name}, il y a des enfants sans choix de module."
        break
      end
    end

    if flash[:alert]
      redirect_back(fallback_location: root_path)
    else
      service = Child::ExportBooksV2Service.new(group_ids: ids).call
      if service.errors.empty?
        send_file service.zip_file.path, type: 'application/zip', x_sendfile: true,
                                         disposition: 'attachment', filename: "#{Time.zone.today.strftime('%d-%m-%Y')}.zip"
      else
        flash[:alert] = service.errors
        redirect_back(fallback_location: root_path)
      end
    end
  end
end
