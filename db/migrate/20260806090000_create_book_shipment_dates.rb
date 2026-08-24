class CreateBookShipmentDates < ActiveRecord::Migration[7.0]

  def change
    create_table :book_shipment_dates do |t|
      t.date :date, null: false

      t.timestamps
    end
    add_index :book_shipment_dates, :date, unique: true
  end
end
