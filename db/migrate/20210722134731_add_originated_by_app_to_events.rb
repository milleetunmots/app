class AddOriginatedByAppToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :originated_by_app, :boolean, default: true
  end
end
