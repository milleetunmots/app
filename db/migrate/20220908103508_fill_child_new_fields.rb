class FillChildNewFields < ActiveRecord::Migration[6.0]
  def change
    Child.tagged_with("age_ok").each {|child| child.update! available_for_workshops: true}
    Child.tagged_with("Famille suivie").each {|child| child.update! family_followed: true}
  end
end
