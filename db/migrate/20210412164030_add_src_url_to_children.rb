class AddSrcUrlToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :src_url, :string
  end
end
