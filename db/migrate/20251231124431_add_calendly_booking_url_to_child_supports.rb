class AddCalendlyBookingUrlToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :calendly_booking_url, :string
  end
end
