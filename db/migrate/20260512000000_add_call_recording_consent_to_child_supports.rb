class AddCallRecordingConsentToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :call_recording_consent, :string, default: 'not_asked'
  end
end
