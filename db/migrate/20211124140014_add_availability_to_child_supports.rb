class AddAvailabilityToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :availability, :string
  end
end
