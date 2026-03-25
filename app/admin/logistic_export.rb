ActiveAdmin.register LogisticExport do
  menu label: 'Exports YLS'

  config.sort_order = 'created_at_desc'

  filter :by_group_ids,
         as: :select,
         multiple: true,
         collection: -> { Group.kept.order(:name).pluck(:name, :id) },
         label: 'Cohortes',
         input_html: { data: { select2: {} } }
  filter :created_at

  index do
    id_column
    column('Cohortes / Modules') do |export|
      safe_join(export.group_module_labels.map { |label| content_tag(:span, label, class: 'status_tag yes') }, ' ')
    end
    column :created_at
    column('Archive') do |export|
      if export.archive.attached?
        link_to 'Télécharger ZIP', download_admin_logistic_export_path(export)
      end
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row('Cohortes / Modules') do |export|
        safe_join(export.group_module_labels.map { |label| content_tag(:span, label, class: 'status_tag yes') }, ' ')
      end
      row :created_at
      row('Archive') do |export|
        if export.archive.attached?
          link_to 'Télécharger ZIP', download_admin_logistic_export_path(export)
        end
      end
    end
  end

  member_action :download, method: :get do
    if resource.archive.attached?
      send_data resource.archive.download,
                filename: resource.archive.filename.to_s,
                type: resource.archive.content_type,
                disposition: 'attachment'
    else
      flash[:alert] = "Aucun fichier disponible"
      redirect_to admin_logistic_export_path(resource)
    end
  end
end
