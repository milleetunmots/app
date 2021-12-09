class CreateWelcomeFormResponse < ActiveRecord::Migration[6.0]
  def change
    create_table :welcome_form_responses, id: false do |t|
      t.string :response_id
      t.json :form_item

      t.index :response_id, unique: true
    end
  end
end
