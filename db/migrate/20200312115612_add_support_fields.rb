class AddSupportFields < ActiveRecord::Migration[6.0]
  def change
    # new columns

    add_column :child_supports, :call1_language_awareness, :string
    add_column :child_supports, :call1_goals, :text
    add_column :child_supports, :call2_reading_frequency, :string
    add_column :child_supports, :call3_reading_frequency, :string
    add_column :child_supports, :call2_sendings_benefits, :string
    add_column :child_supports, :call2_sendings_benefits_details, :text

    rename_column :child_supports, :call2_content_usage, :call2_parent_actions
    rename_column :child_supports, :call3_content_usage, :call3_parent_actions

    # migrate existing data

    call2_program_investment_label = {
      '1_low' => 'Faible',
      '2_medium' => 'Modéré',
      '3_high' => 'Important'
    }

    ChildSupport.find_each do |child_support|
      if v = child_support.call2_program_investment
        child_support.call2_notes = [
          "Note d'investissement dans le programme : #{call2_program_investment_label[v.to_s]}",
          child_support.call2_notes
        ].compact.join("\n")
        child_support.save(validate: false)
      end
    end

    # remove columns

    remove_column :child_supports, :call2_program_investment, :string
  end
end
