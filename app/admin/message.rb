ActiveAdmin.register_page "Message" do
  content do

    render "admin/message/new"

    label do 
      'Date d\'envoie du message'
    end
    form action: admin_message_program_sms_path, method: :post do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token

      fieldset class: 'inputs' do
        ol do
          li class: 'datepicker input required stringish' do
            f.input :started_at, as: :datepicker
          end
        end
      end

      label do
        'Parents et/ou cohorte'
      end
      f.input type: 'search', name: 'search' do
      end

      label do
        'Message'
      end
      textarea name: 'message' do
      end

      button do
        'Envoyer'
      end
    end
  end


  page_action :program_sms, method: :post do
    puts 'Wow, actually doing!'
    redirect_to 'http://stackoverflow.com'
  end

end
