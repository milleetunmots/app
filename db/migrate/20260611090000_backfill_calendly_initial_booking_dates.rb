class BackfillCalendlyInitialBookingDates < ActiveRecord::Migration[7.0]

  # Les familles dont le 1er SMS de prise de RDV a été envoyé par l'ancien flux
  # hebdomadaire n'ont pas de calendly_initial_booking_dates : sans backfill,
  # le job quotidien leur renverrait le 1er SMS et la relance à J+2 ne
  # partirait jamais. On reprend calendly_last_booking_dates (égal à la date du
  # 1er SMS tant qu'aucune relance n'a eu lieu), normalisé en date.
  def up
    Parent.where.not(calendly_last_booking_dates: {}).find_each do |parent|
      initial_dates = parent.calendly_last_booking_dates.transform_values do |value|
        value.to_date.to_s
      rescue ArgumentError, TypeError
        value
      end
      parent.update_columns(calendly_initial_booking_dates: initial_dates)
    end
  end

  def down
    Parent.where.not(calendly_initial_booking_dates: {}).update_all(calendly_initial_booking_dates: {})
  end
end
