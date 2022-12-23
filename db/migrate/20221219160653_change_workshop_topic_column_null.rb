class ChangeWorkshopTopicColumnNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :workshops, :topic, true
  end
end
