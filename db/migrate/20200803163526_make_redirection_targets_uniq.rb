class MakeRedirectionTargetsUniq < ActiveRecord::Migration[6.0]
  def change
    remove_index :redirection_targets, :medium_id
    add_index :redirection_targets, :medium_id, unique: true
  end
end
