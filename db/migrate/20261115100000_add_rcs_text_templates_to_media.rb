class AddRcsTextTemplatesToMedia < ActiveRecord::Migration[7.0]

  def change
    # Type du modèle RCS enregistré par message : texte (true) ou carte (false). Spot-Hit refuse de changer le type d'un modèle.
    change_table :media, bulk: true do |t|
      t.boolean :rcs_text_template1, default: false, null: false
      t.boolean :rcs_text_template2, default: false, null: false
      t.boolean :rcs_text_template3, default: false, null: false
    end
  end
end
