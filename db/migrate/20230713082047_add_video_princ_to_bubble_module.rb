class AddVideoPrincToBubbleModule < ActiveRecord::Migration[6.0]
  def change
    add_reference :bubble_modules, :video_princ, foreign_key: { to_table: :bubble_videos }
  end
end
