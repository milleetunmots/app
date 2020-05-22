module ActiveAdmin
  module BetterCSV
    module DSL

      # Call this inside your resource definition to improve CSV export
      #
      # Example:
      #
      # #app/admin/players.rb
      #
      # ActiveAdmin.register Player do
      #   # Improve CSV
      #   has_better_csv
      # end
      def has_better_csv
        controller do
          def csv_filename
            klass = if collection.is_a?(ActiveRecord::Relation)
              collection.klass
            else
              collection.object.klass
            end

            [
              klass.model_name.human.pluralize(:fr),
              current_scope&.name,
              Time.zone.now.to_date.to_s(:default)
            ].compact.join(' - ') + '.csv'
          end
        end
      end

    end
  end
end
