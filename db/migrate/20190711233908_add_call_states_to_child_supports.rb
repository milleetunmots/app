class AddCallStatesToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call1_status, :string
    add_column :child_supports, :call2_status, :string
    add_column :child_supports, :call3_status, :string
  end
end
