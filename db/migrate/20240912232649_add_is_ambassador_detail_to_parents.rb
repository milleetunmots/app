class AddIsAmbassadorDetailToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :is_ambassador_detail, :text
  end
end
