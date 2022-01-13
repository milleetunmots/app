class WorkshopDecorator < BaseDecorator
  def workshop_address
    "#{address} #{postal_code} #{city_name}"
  end

  def workshop_participants
    arbre do
      ul do
        participants.decorate.each do |participant|
          li do
            participant.admin_link
          end
        end
      end
    end
  end
end
