class RenameCallStatusIncomplet < ActiveRecord::Migration[6.0]
  def change
    (0..5).each do |call_idx|
      ChildSupport.where("call#{call_idx}_status = 'Incomplet'").update_all("call#{call_idx}_status" => 'Incomplet / Pas de choix de module')
    end
  end
end
