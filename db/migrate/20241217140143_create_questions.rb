class CreateQuestions < ActiveRecord::Migration[6.1]
  def change
    create_table :questions do |t|
      t.belongs_to :survey, null: false
      t.text :body, null: false
      t.boolean :with_open_ended_response, null: false, default: true

      t.timestamps
    end
  end
end
