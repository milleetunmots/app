class AddCalendlyBookingUrlToParents < ActiveRecord::Migration[7.0]
  def change
    add_column :parents, :calendly_booking_urls, :jsonb, default: {}
  end
end
