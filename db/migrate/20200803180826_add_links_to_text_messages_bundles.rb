class AddLinksToTextMessagesBundles < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :media, :link1, foreign_key: { to_table: :media }
    add_belongs_to :media, :link2, foreign_key: { to_table: :media }
    add_belongs_to :media, :link3, foreign_key: { to_table: :media }
  end
end
