class DropRedirectionUrlSent < ActiveRecord::Migration[6.0]
  def change
    drop_table :redirection_url_sents
  end
end
