class AddEnableCallRecordingToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :enable_calls_recording, :boolean, null: false, default: false
  end
end
