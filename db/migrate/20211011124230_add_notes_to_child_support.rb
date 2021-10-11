class AddNotesToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :notes, :text
  end
end
