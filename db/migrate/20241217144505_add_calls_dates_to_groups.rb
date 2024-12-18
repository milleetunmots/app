class AddCallsDatesToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :call0_start_date, :date
    add_column :groups, :call0_end_date, :date
    add_column :groups, :call1_start_date, :date
    add_column :groups, :call1_end_date, :date
    add_column :groups, :call2_start_date, :date
    add_column :groups, :call2_end_date, :date
    add_column :groups, :call3_start_date, :date
    add_column :groups, :call3_end_date, :date
  end
end
