class CreateFieldComments < ActiveRecord::Migration[6.0]
  def change
    create_table :field_comments do |t|
      t.belongs_to :author, foreign_key: { to_table: :admin_users }
      t.belongs_to :related, polymorphic: true
      t.string :field
      t.text :content
      t.timestamps
    end
  end
end
