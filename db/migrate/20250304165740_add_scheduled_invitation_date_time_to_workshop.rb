class AddScheduledInvitationDateTimeToWorkshop < ActiveRecord::Migration[6.1]
  def change
    add_column :workshops, :scheduled_invitation_date_time, :datetime
  end
end
