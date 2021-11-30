class AddParentsToWorkshops < ActiveRecord::Migration[6.0]
  def change
    add_reference :events, :workshop
  end
end
