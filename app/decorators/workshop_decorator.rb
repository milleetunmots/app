class WorkshopDecorator < BaseDecorator
  def workshop_address
    "#{address} #{postal_code} #{city_name}"
  end
end
