class AddThemeToSupportModules < ActiveRecord::Migration[6.0]
  def change
    add_column :support_modules, :theme, :string
  end
end
