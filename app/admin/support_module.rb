ActiveAdmin.register SupportModule do
  menu parent: 'Médiathèque', label: 'Modules', priority: 0

  decorate_with SupportModuleDecorator

  has_paper_trail
  has_tags
  has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :start_at
    column :display_theme
    column :display_age_ranges
    column :for_bilingual
    column :tags do |model|
      model.tags(context: 'tags')
    end
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item(*args)
      end
    end
  end

  filter :name
  filter :for_bilingual,
         input_html: { data: { select2: {} } }
  filter :start_at
  filter :theme,
         as: :select,
         collection: proc { support_module_theme_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :age_ranges,
         as: :select,
         collection: proc { support_module_age_range_select_collection },
         input_html: { multiple: true, data: { select2: {} } }

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :name
      f.input :for_bilingual
      f.input :theme, collection: support_module_theme_select_collection, input_html: { data: { select2: {} } }
      f.input :age_ranges, multiple: true, collection: support_module_age_range_select_collection, input_html: { data: { select2: {} } }
      f.input :start_at, as: :datepicker
      f.input :picture, as: :file,
                        hint: f.object.id && "Laissez ce champ vide pour ne pas modifier l'image"
      tags_input(f)
    end
    f.inputs do
      f.has_many :support_module_weeks,
                 heading: 'Semaines',
                 new_record: 'Ajouter une semaine',
                 allow_destroy: true,
                 sortable: :position,
                 sortable_start: 1 do |fmwf|
        fmwf.input :medium,
                   collection: support_module_week_medium_select_collection,
                   input_html: { data: { select2: {} } }
        fmwf.input :has_been_sent1
        fmwf.input :has_been_sent2
        fmwf.input :has_been_sent3
        fmwf.input :additional_medium,
                   collection: support_module_week_additional_medium_select_collection,
                   input_html: { data: { select2: {} } }
        fmwf.input :has_been_sent4
      end
    end
    f.actions
  end

  permit_params :name, :start_at, :picture, :support_module_weeks, :for_bilingual, :theme,
  {
    support_module_weeks_attributes: %i[
      id medium_id position
      has_been_sent1 has_been_sent2 has_been_sent3
      additional_medium_id
      has_been_sent4
      _destroy
    ]
  }.merge(tags_params, age_ranges: [])

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :for_bilingual
      row :display_theme
      row :display_age_ranges
      row :start_at
      row :picture do |decorated|
        decorated.picture_tag(max_height: '100px')
      end
      row :tags
      row :created_at
      row :updated_at
    end
    panel '', class: 'support-module-week-lines' do
      resource.support_module_weeks.decorate.each_with_index do |support_module_week, _idx|
        panel support_module_week.title, class: 'support-module-week-line' do
          if support_module_week.medium
            columns do
              (1..3).each do |msg_idx|
                column do
                  if support_module_week.medium.send("body#{msg_idx}").blank?
                    link_to 'Vide',
                            [:admin, support_module_week.medium],
                            target: '_blank'
                  else
                    classes = if support_module_week.send("has_been_sent#{msg_idx}?")
                                'sent'
                              else
                                'not-sent'
                              end
                    support_module_week.medium.decorate.as_card(msg_idx, class: classes)
                  end
                end
              end
              if support_module_week.additional_medium
                column do
                  classes = if support_module_week.has_been_sent4?
                              'sent'
                            else
                              'not-sent'
                            end
                  support_module_week.additional_medium.decorate.as_card(1, class: classes)
                end
              end
            end
          else
            span 'Vide'
          end
        end
      end
    end
  end

  action_item :duplicate, only: :show do
    link_to 'Dupliquer', [:duplicate, :admin, resource], class: 'green'
  end

  member_action :duplicate do
    new_resource = resource.duplicate
    new_resource.save!
    redirect_to [:admin, new_resource]
  end
end
