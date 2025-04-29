class AddBookDeliveryOrganisationNameToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :book_delivery_organisation_name, :string
  end
end
