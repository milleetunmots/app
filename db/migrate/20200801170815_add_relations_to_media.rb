class AddRelationsToMedia < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :media, :image1, foreign_key: { to_table: :media }
    add_belongs_to :media, :image2, foreign_key: { to_table: :media }
    add_belongs_to :media, :image3, foreign_key: { to_table: :media }
  end
end
