class AddRedirectionTargetToPlaces < ActiveRecord::Migration[6.1]
  def change
    add_reference :places, :redirection_target, null: true, foreign_key: true
  end
end
