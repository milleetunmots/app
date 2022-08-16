class AddTypeformInfoToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :other_phone_number, :string
    add_column :child_supports, :child_count, :integer
    add_column :child_supports, :call1_tv_frequency, :string
    add_column :child_supports, :call2_tv_frequency, :string
    add_column :child_supports, :call3_tv_frequency, :string
    add_column :child_supports, :call4_tv_frequency, :string
    add_column :child_supports, :call5_tv_frequency, :string
    add_column :child_supports, :most_present_parent, :string
    add_column :child_supports, :already_working_with, :boolean
    
    add_index :child_supports, :call1_tv_frequency
  end
end

