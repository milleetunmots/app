class AddRawTranscriptionPayloadToAircallCalls < ActiveRecord::Migration[7.0]
  def change
    add_column :aircall_calls, :raw_transcription_payload, :jsonb
  end
end
