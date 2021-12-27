class AddInvitationMessageToWorkshop < ActiveRecord::Migration[6.0]
  def change
    add_column :workshops, :invitation_message, :text
  end
end
