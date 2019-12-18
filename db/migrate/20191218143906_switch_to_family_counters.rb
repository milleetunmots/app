class SwitchToFamilyCounters < ActiveRecord::Migration[6.0]
  def change
    rename_column :children, :redirection_unique_visit_rate, :family_redirection_unique_visit_rate
    rename_column :children, :redirection_url_unique_visits_count, :family_redirection_url_unique_visits_count
    rename_column :children, :redirection_url_visits_count, :family_redirection_url_visits_count
    rename_column :children, :redirection_urls_count, :family_redirection_urls_count
    rename_column :children, :redirection_visit_rate, :family_redirection_visit_rate

    rename_column :redirection_targets, :redirection_url_unique_visits_count, :family_redirection_url_unique_visits_count
    rename_column :redirection_targets, :redirection_url_visits_count, :family_redirection_url_visits_count
    rename_column :redirection_targets, :unique_visit_rate, :family_unique_visit_rate
    rename_column :redirection_targets, :visit_rate, :family_visit_rate

    add_column :redirection_targets, :family_redirection_urls_count, :integer
  end
end
