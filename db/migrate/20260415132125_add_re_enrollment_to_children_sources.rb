class AddReEnrollmentToChildrenSources < ActiveRecord::Migration[7.0]
  def change
    add_column :children_sources, :re_enrollment, :boolean, default: false
  end
end
