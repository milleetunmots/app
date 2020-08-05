ActiveAdmin.register FieldComment do

  decorate_with FieldCommentDecorator

  has_better_csv

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related, :author

  index do
    selectable_column
    id_column
    column :author, sortable: :author_id
    column :related do |decorated|
      decorated.related_link
    end
    column :field
    column :content
    column :created_at do |decorated|
      decorated.created_at_date
    end
    column :updated_at do |decorated|
      decorated.updated_at_date
    end
    actions
  end

  scope(:mine, default: true, group: :author) { |scope| scope.posted_by(current_admin_user) }
  scope :all, group: :author

  filter :author
  filter :content
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors
    f.inputs do
      if related = f.object.related&.decorate
        li class: :input do
          label I18n.t('activerecord.attributes.field_comment.related'), class: :label
          div style: "padding-top: 6px" do
            if related.respond_to?(:admin_link)
              related.admin_link
            else
              auto_link related
            end
          end
        end
      end

      f.input :related_type, as: :hidden
      f.input :related_id, as: :hidden

      f.input :field,
              collection: f.object.related.attributes.keys.map { |k|
                (
                  !%w(
                    id
                    created_at updated_at
                    type
                    discarded_at
                  ).include?(k)
                ) && [
                  f.object.related.class.human_attribute_name(k),
                  k
                ] || nil
              }.compact,
              input_html: { data: { select2: {} } }

      f.input :content, input_html: { rows: 10 }

      f.input :author,
              input_html: { data: { select2: {} } }
    end
    f.actions
  end

  permit_params :author_id, :related_type, :related_id,
                :field, :content

  controller do
    def build_new_resource
      resource = super
      resource.author = current_admin_user
      resource
    end
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :author
      row :related
      row :field
      row :content
      row :created_at
      row :updated_at
    end
  end

end
