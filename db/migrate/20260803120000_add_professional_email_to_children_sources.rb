class AddProfessionalEmailToChildrenSources < ActiveRecord::Migration[7.0]
  def change
    add_column :children_sources, :professional_email, :string
  end
end