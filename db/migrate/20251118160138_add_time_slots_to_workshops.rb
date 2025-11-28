class AddTimeSlotsToWorkshops < ActiveRecord::Migration[6.1]
  def change
    add_column :workshops, :first_workshop_time_slot, :time, null: false, default: '10:00'
    add_column :workshops, :second_workshop_time_slot, :time
  end
end
