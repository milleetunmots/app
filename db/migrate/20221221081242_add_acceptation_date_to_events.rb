class AddAcceptationDateToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :acceptation_date, :date
  end
end
