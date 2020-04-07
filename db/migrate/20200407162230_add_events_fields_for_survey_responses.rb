class AddEventsFieldsForSurveyResponses < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :subject, :string
  end
end
