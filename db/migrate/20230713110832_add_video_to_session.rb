class AddVideoToSession < ActiveRecord::Migration[6.0]
  def change
    add_reference :bubble_sessions, :video, foreign_key: { to_table: :bubble_videos }
  end
end
