class CreateRedirections < ActiveRecord::Migration[6.0]
  def change
    create_table :redirection_targets do |t|
      t.string :name
      t.string :target_url, null: false

      t.integer :redirection_urls_count
      t.integer :redirection_url_visits_count
      t.integer :redirection_url_unique_visits_count
      t.float :unique_visit_rate
      t.float :visit_rate

      t.timestamps
    end

    create_table :redirection_urls do |t|
      t.belongs_to :redirection_target
      t.belongs_to :parent
      t.belongs_to :child

      t.string :security_code

      t.integer :redirection_url_visits_count

      t.timestamps
    end

    create_table :redirection_url_visits do |t|
      t.belongs_to :redirection_url

      t.datetime :occurred_at
    end

    add_column :parents, :redirection_urls_count, :integer
    add_column :parents, :redirection_url_visits_count, :integer
    add_column :parents, :redirection_url_unique_visits_count, :integer
    add_column :parents, :redirection_unique_visit_rate, :float
    add_column :parents, :redirection_visit_rate, :float

    add_column :children, :redirection_urls_count, :integer
    add_column :children, :redirection_url_visits_count, :integer
    add_column :children, :redirection_url_unique_visits_count, :integer
    add_column :children, :redirection_unique_visit_rate, :float
    add_column :children, :redirection_visit_rate, :float
  end
end
