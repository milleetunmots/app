class AddIdContenuToBubbleContents < ActiveRecord::Migration[6.1]
  def change
    add_column :bubble_contents, :id_contenu, :string
  end
end
