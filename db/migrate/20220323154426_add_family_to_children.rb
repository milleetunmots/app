class AddFamilyToChildren < ActiveRecord::Migration[6.0]
  def change
    add_reference :children, :family, foreign_key: true
  end
end
