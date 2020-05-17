class AddDiscardedAtToOtherModels < ActiveRecord::Migration[6.0]
  def change
    %w(children parents).each do |table|
      add_column table, :discarded_at, :datetime
      add_index table, :discarded_at
    end
  end
end
