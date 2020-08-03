class AddThemeToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :theme, :string, index: true
  end
end
