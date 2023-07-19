class AddModuleToBubbleSession < ActiveRecord::Migration[6.0]
  def change
    add_reference :bubble_sessions, :module_session, foreign_key: { to_table: :bubble_modules }
  end
end
