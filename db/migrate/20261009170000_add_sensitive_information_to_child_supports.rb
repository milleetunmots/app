class AddSensitiveInformationToChildSupports < ActiveRecord::Migration[7.0]
  def change
    add_column :child_supports, :sensitive_information, :text
  end
end
