class AddTermsAcceptedAtToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :terms_accepted_at, :datetime
    Parent.update_all("terms_accepted_at = created_at")
  end
end
