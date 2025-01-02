class CreateQuestions < ActiveRecord::Migration[6.1]
  def change
    create_table :questions do |t|
      t.belongs_to :survey, null: false
      t.text :name, null: false
      t.boolean :with_open_ended_response, null: false, default: false
      t.text :uid, null: false

      t.timestamps
    end

    add_index :questions, :uid, unique: true
  end
end
