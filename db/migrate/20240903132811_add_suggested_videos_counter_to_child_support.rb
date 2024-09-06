class AddSuggestedVideosCounterToChildSupport < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :suggested_videos_counter, :jsonb, array: true, default: []
  end
end
