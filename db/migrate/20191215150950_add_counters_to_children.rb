class AddCountersToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :redirection_urls_count, :integer
    add_column :children, :redirection_url_visits_count, :integer
    add_column :children, :redirection_url_unique_visits_count, :integer
    add_column :children, :redirection_unique_visit_rate, :float
    add_column :children, :redirection_visit_rate, :float
  end
end
