ActiveAdmin.register Book do

  decorate_with BookDecorator

  actions :all, except: %i[new edit]

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :ean
    column :title
    column :book_support_modules
    column :file do |decorated|
      decorated.cover_link_tag(max_height: '50px')
    end
  end

  filter :ean
  filter :title

  show do
    attributes_table do
      row :ean
      row :title
      row :book_support_modules
      row :file do |decorated|
        decorated.cover_link_tag(max_height: '500px')
      end
    end
  end
end
