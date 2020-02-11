class AddCall3SendingsBenefitsDetailsToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call3_sendings_benefits_details, :text
  end
end
