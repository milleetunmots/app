class CreateGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :groups do |t|
      t.string :name
      t.date :started_at
      t.date :ended_at

      t.timestamps null: false
    end

    create_table :children_groups do |t|
      t.belongs_to :child
      t.belongs_to :group

      t.date :quit_at

      t.timestamps null: false
    end
  end
end
