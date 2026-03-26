class AddEnrollmentReasonsToChildSupports < ActiveRecord::Migration[7.0]
  def change
    add_column :child_supports, :enrollment_reasons, :string, array: true, default: []
  end
end
