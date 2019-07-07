class CreateSupports < ActiveRecord::Migration[6.0]
  def change
    create_table :child_supports do |t|
      # permament information
      t.text :important_information

      # call 1
      t.text :call1_parent_actions
      t.text :call1_language_development
      t.string :call1_parent_progress, index: true
      t.text :call1_notes

      # call 2
      t.text :call2_technical_information
      t.text :call2_content_usage
      t.string :call2_program_investment, index: true
      t.text :call2_language_development
      t.text :call2_goals
      t.text :call2_notes

      # call 3
      t.text :call3_technical_information
      t.text :call3_content_usage
      t.string :call3_program_investment, index: true
      t.text :call3_language_development
      t.text :call3_goals
      t.text :call3_notes

      t.timestamps null: false
    end

    add_reference :children, :child_support, index: true
  end
end
