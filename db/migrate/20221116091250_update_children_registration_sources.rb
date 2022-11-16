class UpdateChildrenRegistrationSources < ActiveRecord::Migration[6.0]
  def change
    Child.where(registration_source: "resubscribing").update_all(registration_source: "other")
  end
end
