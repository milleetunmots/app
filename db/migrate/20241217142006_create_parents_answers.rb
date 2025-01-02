class CreateParentsAnswers < ActiveRecord::Migration[6.1]
  def change
    create_table :parents_answers do |t|
      t.belongs_to :parent, null: false
      t.belongs_to :answer, null: false

      t.timestamps
    end
  end
end
