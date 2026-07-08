class FormatParentsAndChildrenNames < ActiveRecord::Migration[7.0]

  def up
    %w[parents children].each do |table|
      execute <<~SQL.squish
        UPDATE #{table}
        SET first_name = INITCAP(TRIM(first_name)),
            last_name = UPPER(TRIM(last_name))
      SQL
    end
  end

  def down; end
end