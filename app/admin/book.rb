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
  end

  filter :ean
  filter :title

  show do
    attributes_table do
      row :ean
      row :title
      row :book_support_modules
    end
  end
end
