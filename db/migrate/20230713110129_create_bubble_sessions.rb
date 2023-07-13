class CreateBubbleSessions < ActiveRecord::Migration[6.0]
  def change
    create_table :bubble_sessions do |t|
      t.string :avis_contenu
      t.string :avis_video
      t.string :child_session
      t.datetime :derniere_ouverture
      t.date :created_date
      t.string :lien
      t.integer :pourcentage_video
      t.integer :avis_rappel
    end
  end
end
