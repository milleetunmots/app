class ConvertChildSupportCallDurationsIntoIntegers < ActiveRecord::Migration[6.0]
  def change
    remove_column :child_supports, :call1_duration
    add_column :child_supports, :call1_duration, :integer
    remove_column :child_supports, :call2_duration
    add_column :child_supports, :call2_duration, :integer
    remove_column :child_supports, :call3_duration
    add_column :child_supports, :call3_duration, :integer
  end
end
