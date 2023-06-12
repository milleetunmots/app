class AddMidTermFormResponsesToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :mid_term_rate, :integer
    add_column :parents, :mid_term_reaction, :string
    add_column :parents, :mid_term_speech, :text
  end
end
