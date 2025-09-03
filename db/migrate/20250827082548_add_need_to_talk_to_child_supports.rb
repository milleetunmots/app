class AddNeedToTalkToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :call0_talk_needed, :boolean, null: false, default: false
    add_column :child_supports, :call1_talk_needed, :boolean, null: false, default: false
    add_column :child_supports, :call2_talk_needed, :boolean, null: false, default: false
    add_column :child_supports, :call3_talk_needed, :boolean, null: false, default: false
    add_column :child_supports, :call4_talk_needed, :boolean, null: false, default: false
    add_column :child_supports, :call5_talk_needed, :boolean, null: false, default: false

    add_column :child_supports, :call0_why_talk_needed, :text
    add_column :child_supports, :call1_why_talk_needed, :text
    add_column :child_supports, :call2_why_talk_needed, :text
    add_column :child_supports, :call3_why_talk_needed, :text
    add_column :child_supports, :call4_why_talk_needed, :text
    add_column :child_supports, :call5_why_talk_needed, :text
  end
end
