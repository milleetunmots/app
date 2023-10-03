class AddContentToBubbleSessions < ActiveRecord::Migration[6.0]
  def change
    add_reference :bubble_sessions, :content, foreign_key: { to_table: :bubble_contents }
  end
end
