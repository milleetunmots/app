class ChangeBubbleVideoColumns < ActiveRecord::Migration[6.0]
  def change
    add_column :bubble_videos, :avis_rappel_temp, :integer
    add_column :bubble_videos, :avis_nouveaute_temp, :integer
    add_column :bubble_videos, :avis_pas_adapte_temp, :integer

    execute("UPDATE bubble_videos SET avis_rappel_temp = CAST(avis_rappel AS integer)")
    execute("UPDATE bubble_videos SET avis_nouveaute_temp = CAST(avis_nouveaute AS integer)")
    execute("UPDATE bubble_videos SET avis_pas_adapte_temp = CAST(avis_pas_adapte AS integer)")

    remove_column :bubble_videos, :avis_rappel
    remove_column :bubble_videos, :avis_nouveaute
    remove_column :bubble_videos, :avis_pas_adapte

    rename_column :bubble_videos, :avis_rappel_temp, :avis_rappel
    rename_column :bubble_videos, :avis_nouveaute_temp, :avis_nouveaute
    rename_column :bubble_videos, :avis_pas_adapte_temp, :avis_pas_adapte
  end
end
