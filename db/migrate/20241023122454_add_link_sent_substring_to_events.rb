class AddLinkSentSubstringToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :link_sent_substring, :string
  end
end
