class AddCalendlyInitialBookingDateToParents < ActiveRecord::Migration[7.0]
  def change
    add_column :parents, :calendly_initial_booking_dates, :jsonb, default: {}
  end
end
