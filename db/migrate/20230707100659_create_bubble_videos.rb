class CreateBubbleVideos < ActiveRecord::Migration[6.0]
  def change
    create_table :bubble_videos do |t|
      t.integer :like
      t.integer :dislike
      t.integer :views
      t.text :commentaires
      t.string :lien
      t.string :video
      t.date :created_date, null: false
    end
  end
end
