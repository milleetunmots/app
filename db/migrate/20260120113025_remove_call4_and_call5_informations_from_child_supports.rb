class RemoveCall4AndCall5InformationsFromChildSupports < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.connection.columns(:child_supports)
                      .map(&:name)
                      .select { |column| column.starts_with?('call4', 'call5') }
                      .map(&:to_sym).each do |attribute|
      remove_column :child_supports, attribute
    end
  end
end
