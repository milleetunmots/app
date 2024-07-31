class AddPreferredChannelToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :preferred_channel, :string
  end
end
