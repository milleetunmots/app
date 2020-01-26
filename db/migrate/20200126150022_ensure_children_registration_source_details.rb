class EnsureChildrenRegistrationSourceDetails < ActiveRecord::Migration[6.0]
  def change
    Child.where(registration_source_details: nil).update_all(registration_source_details: '?')
  end
end
