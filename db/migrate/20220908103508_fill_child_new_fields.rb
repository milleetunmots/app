class FillChildNewFields < ActiveRecord::Migration[6.0]
  def change
    Child.tagged_with("age_ok").each {|child| child.update! available_for_workshops: true}
    Parent.tagged_with("Famille suivie").each {|parent| parent.update! family_followed: true}
  end
end
