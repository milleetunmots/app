class AddIndexesToVersions < ActiveRecord::Migration[6.1]
  def change
    add_index :versions, :whodunnit
  end
end
