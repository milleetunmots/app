class AddOptionsToAnswers < ActiveRecord::Migration[6.1]
  def change
    add_column :answers, :options, :text, array: true
  end
end
