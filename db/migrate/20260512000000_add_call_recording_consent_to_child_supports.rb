class AddCallRecordingConsentToChildSupports < ActiveRecord::Migration[7.0]
  def change
    add_column :child_supports, :call_recording_consent, :string
  end
end
