class CreateChildSupportCall3SendingsBenefits < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call3_sendings_benefits, :string
    remove_column :child_supports, :call3_program_investment, :string
  end
end
