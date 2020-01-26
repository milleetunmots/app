ActiveAdmin.register Events::TextMessage do

  menu parent: 'Événements'

  actions :index, :show

  decorate_with Events::TextMessageDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related

  index do
    selectable_column
    id_column
    column :related do |model|
      model.related_link
    end
    column :occurred_at do |model|
      l model.occurred_at.to_date, format: :default
    end
    column :body
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions
  end

  filter :occurred_at
  filter :created_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :related do |model|
        model.related_link
      end
      row :occurred_at
      row :body
      row :created_at
    end
  end

end
