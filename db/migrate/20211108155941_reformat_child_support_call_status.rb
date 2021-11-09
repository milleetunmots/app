class ReformatChildSupportCallStatus < ActiveRecord::Migration[6.0]
  def change
    (1..5).each do |call_idx|
      ChildSupport.where("unaccent(call#{call_idx}_status) ILIKE unaccent(?)", 'OK').each do |child_support|
        child_support.update_column "call#{call_idx}_status".to_sym, 'OK'
      end
      ChildSupport.where("unaccent(call#{call_idx}_status) ILIKE unaccent(?)", 'K0').each do |child_support|
        child_support.update_column "call#{call_idx}_status".to_sym, 'KO'
      end
    end
  end
end
