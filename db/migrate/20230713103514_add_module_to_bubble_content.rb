class AddModuleToBubbleContent < ActiveRecord::Migration[6.0]
  def change
    add_reference :bubble_contents, :module_content, foreign_key: { to_table: :bubble_modules }
  end
end
