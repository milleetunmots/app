ActiveAdmin.register Book do

  decorate_with BookDecorator

  actions :all, except: %i[new edit]

  collection_action :upsert_shipment_date, method: :post do
    authorize!(:upsert_shipment_date, Book)

    shipment_date = BookShipmentDate.find_or_initialize_by(id: params[:id].presence)
    shipment_date.date = params[:date]

    unless shipment_date.save
      render json: { ok: false, errors: shipment_date.errors.full_messages }, status: :unprocessable_entity
      return
    end

    payload = { ok: true, id: shipment_date.id }

    # Modifier la 1ère date décale la 2ème sur le cycle de 45 jours.
    if params[:position].to_s == '0'
      following = BookShipmentDate.reschedule_following(shipment_date)
      if following.errors.any?
        payload[:warning] = "La 2ème date n'a pas pu être recalculée : #{following.errors.full_messages.join(', ')}"
      else
        payload[:following] = { id: following.id, date: following.date.iso8601 }
      end
    end

    render json: payload
  end

  action_item :sav_management, only: :index do
    link_to 'Gestion du SAV', new_sav_import_admin_books_path if authorized?(:sav_management, Book)
  end

  collection_action :new_sav_import do
    authorize!(:sav_management, Book)

    @import_action = perform_sav_import_admin_books_path
  end

  collection_action :perform_sav_import, method: :post do
    authorize!(:sav_management, Book)

    if params[:csv_file].blank?
      redirect_to new_sav_import_admin_books_path, alert: 'Veuillez sélectionner un fichier csv.'
      return
    end

    service = Book::SavImportService.new(csv_file: params[:csv_file]).call
    @matched_count = service.matched_count
    @errors = service.errors
    render :sav_import_results
  end

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    if authorized?(:upsert_shipment_date, Book)
      div do
        render 'index_top'
      end
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
