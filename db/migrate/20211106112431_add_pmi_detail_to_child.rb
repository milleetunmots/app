class AddPmiDetailToChild < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :pmi_detail, :string
  end
end
