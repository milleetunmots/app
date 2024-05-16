class AddFamilySupportShouldBeStoppedToChildSupport < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :family_support_should_be_stopped, :string
  end
end
