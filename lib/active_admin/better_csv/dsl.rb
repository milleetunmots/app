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
            [
              collection.object.klass.model_name.human.pluralize,
              current_scope&.name,
              Time.zone.now.to_date.to_s(:default)
            ].compact.join(' - ') + '.csv'
          end
        end
      end

    end
  end
end
