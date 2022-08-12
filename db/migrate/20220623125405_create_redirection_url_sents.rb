class CreateRedirectionUrlSents < ActiveRecord::Migration[6.0]
  def change
    create_table :redirection_url_sents do |t|
      t.belongs_to :redirection_url

      t.datetime :occurred_at
    end
  end
end
