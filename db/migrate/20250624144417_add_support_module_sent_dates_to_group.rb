class AddSupportModuleSentDatesToGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :support_module_sent_dates, :jsonb
  end
end
