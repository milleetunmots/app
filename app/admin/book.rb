ActiveAdmin.register Book do

  decorate_with BookDecorator

  actions :all, except: [:new]

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
end
