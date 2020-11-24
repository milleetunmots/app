class AddNewCallOneFields < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call1_sendings_benefits, :string
    add_column :child_supports, :call1_sendings_benefits_details, :text
    add_column :child_supports, :call1_technical_information, :text
  end
end
