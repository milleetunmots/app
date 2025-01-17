class AddExcludedFromAnalyticsToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :is_excluded_from_analytics, :boolean, null: false, default: false
  end
end
