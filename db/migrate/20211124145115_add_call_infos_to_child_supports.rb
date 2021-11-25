class AddCallInfosToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :call_infos, :string
  end
end
