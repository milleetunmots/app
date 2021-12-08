class CreateWelcomeFormResponse < ActiveRecord::Migration[6.0]
  def change
    create_table :welcome_form_responses do |t|
      t.string :form_phone_number
      t.string :form_last_name
      t.string :degree
      t.string :child_care
      t.integer :books_number
      t.text :parenting_practice
      t.text :initial_motivation

      t.references :parent
    end
  end
end
