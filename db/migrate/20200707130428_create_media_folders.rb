class CreateMediaFolders < ActiveRecord::Migration[6.0]
  def change
    create_table :media_folders do |t|
      t.belongs_to :parent, foreign_key: { to_table: :media_folders }

      t.string :name

      t.timestamps
    end

    add_belongs_to :media, :folder, foreign_key: { to_table: :media_folders }
  end
end
