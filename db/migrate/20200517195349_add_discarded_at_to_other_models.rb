class AddDiscardedAtToOtherModels < ActiveRecord::Migration[6.0]
  def change
    %w(children child_supports groups parents redirection_targets redirection_urls tasks).each do |table|
      add_column table, :discarded_at, :datetime
      add_index table, :discarded_at
    end
  end
end
