class AddHasImportantInformationParentalConsentToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :has_important_information_parental_consent, :boolean, null: false, default: false
  end
end
