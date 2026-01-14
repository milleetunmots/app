class AddTranscriptionNotFoundToAircallCalls < ActiveRecord::Migration[7.0]
  def change
    add_column :aircall_calls, :transcription_not_found, :datetime
  end
end
