module ActiveAdmin
  module Discard
    module DSL

      # Call this inside your resource definition to improve CSV export
      #
      # Example:
      #
      # #app/admin/players.rb
      #
      # ActiveAdmin.register Player do
      #   # Include Discard behavior
      #   use_discard
      # end
      def use_discard
        actions :all, except: [:destroy]

        scope :discarded, group: :discard do |scope|
          scope.with_discarded.discarded
        end

        member_action :discard, method: :put do
          resource.discard!
          redirect_to request.referer,
                      notice: 'Mis à la corbeille'
        end

        member_action :undiscard, method: :put do
          resource.undiscard!
          redirect_to request.referer,
                      notice: 'Sorti de la corbeille'
        end

        member_action :really_destroy, method: :delete do
          resource.destroy
          redirect_to polymorphic_path([:admin, collection.object.klass], scope: :discarded),
                      notice: 'Supprimé'
        end

        action_item :discard,
                    only: :show,
                    if: proc { !resource.discarded? } do
          link_to_discard_resource
        end

        action_item :undiscard,
                    only: :show,
                    if: proc { resource.discarded? } do
          link_to_undiscard_resource
        end

        action_item :really_destroy,
                    only: :show,
                    if: proc { resource.discarded? } do
          link_to_really_destroy_resource
        end
      end

    end
  end
end
