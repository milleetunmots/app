class AddSecondWorkshopTimeSlotToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :workshop_time_slot, :integer
  end
end
