class CreateBubbleVideos < ActiveRecord::Migration[6.0]
  def change
    create_table :bubble_videos do |t|
      t.integer :like
      t.integer :dislike
      t.integer :views
      t.string :lien
      t.string :video
      t.string :video_type
      t.date :created_date, null: false
      t.string :avis_nouveaute
      t.string :avis_pas_adapte
      t.string :avis_rappel
    end
  end
end
