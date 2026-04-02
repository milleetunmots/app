class AddCalendlyLastBookingDateToParents < ActiveRecord::Migration[7.0]
  def change
    add_column :parents, :calendly_last_booking_dates, :jsonb, default: {}
  end
end
