class CreateParentsWorkshops < ActiveRecord::Migration[6.0]
  def change
    create_table :parents_workshops, id: false do |t|
      t.belongs_to :parent
      t.belongs_to :workshop
    end
  end
end
