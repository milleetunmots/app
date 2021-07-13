ActiveAdmin.register_page "Message" do
  
  menu  priority: 12, parent: 'Programmer des envois'

  content do

    form action: admin_message_program_sms_path, method: :post, id: 'sms-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      
      label 'Date et heure d\'envoie du message'
      div class: 'datetime-container' do
        input type: 'text', name: 'planned_date', class: 'datepicker hasDatePicker', style: 'margin-right: 20px;', value: Date.today
        input type: 'time', name: 'planned_hour', value: Time.zone.now.strftime('%H:%M')
      end
      
      div do
        label 'Choisissez les destinataires'
        select name: 'recipients[]', multiple: 'multiple', id: 'recipients'
      end

      div do
        label 'Url cible'
        select name: 'url_cible', id: 'url_cible'
      end


      div do
        label 'Message'
        textarea name: 'message'
      end

      div class: 'actions' do
        div class: 'action input_action' do
          input type: 'submit', value: 'Valider'
        end
      end
    end
  end


  page_action :program_sms, method: :post do
    service = ProgramMessageService.new(
      params[:planned_date], 
      params[:planned_hour], 
      params[:recipients], 
      params[:message], 
      params[:url_cible]
    ).call

    if service.errors.any?
      redirect_back(fallback_location: root_path, alert: service.errors.join("\n"))
    else
      redirect_back(fallback_location: root_path, notice: 'Message(s) programmé(s)')
    end
  end

  page_action :recipients do
    results = (
      Parent.where('unaccent(CONCAT(first_name, last_name)) ILIKE unaccent(?)', "%#{params[:term]}%").decorate +
      Tag.where('unaccent(name) ILIKE unaccent(?)', "%#{params[:term]}%").decorate +
      Group.where('unaccent(name) ILIKE unaccent(?)', "%#{params[:term]}%").decorate
    ).map do |result|
      {
        id: "#{result.object.class.name.underscore}.#{result.id}",
        name: result.name,
        type: result.object.class.name.underscore,
        icon: result.icon_class,
        html: result.as_autocomplete_result
      }
    end

    render json: {
      results: results
    }
  end

  page_action :url_cible do
    results = (
      RedirectionTarget.joins(:medium).where("media.name ILIKE unaccent(?) and media.url IS NOT NULL", "%#{params[:term]}%").decorate).map do |result|
      {
        id: result.id,
        name: result.medium.name,
      }
    end

    render json: {
      results: results
    }
  end

end
