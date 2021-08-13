class AddOriginatedByAppToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :originated_by_app, :boolean, default: true, null: false

    Events::TextMessage.update_all(originated_by_app: false)
  end
end
