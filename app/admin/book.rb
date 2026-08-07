ActiveAdmin.register Book do

  decorate_with BookDecorator

  actions :all, except: %i[new edit]

  collection_action :upsert_shipment_date, method: :post do
    shipment_date = BookShipmentDate.find_or_initialize_by(id: params[:id].presence)
    shipment_date.date = params[:date]

    if shipment_date.save
      render json: { ok: true, id: shipment_date.id }
    else
      render json: { ok: false, errors: shipment_date.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    div do
      render 'index_top'
    end

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
