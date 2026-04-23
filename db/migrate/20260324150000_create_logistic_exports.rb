class CreateLogisticExports < ActiveRecord::Migration[7.0]
  def change
    create_table :logistic_exports do |t|
      t.jsonb :group_modules, null: false, default: []

      t.timestamps
    end
  end
end