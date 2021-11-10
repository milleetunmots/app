class ReformatChildSupportCallStatus < ActiveRecord::Migration[6.0]
  def change
    (1..5).each do |call_idx|
      ChildSupport.where("unaccent(call#{call_idx}_status) ILIKE unaccent('%OK%')").update_all("call#{call_idx}_status" => "OK")
      ChildSupport.where("unaccent(call#{call_idx}_status) ILIKE unaccent('%KO%')").update_all("call#{call_idx}_status" => "KO")
    end
  end
end
