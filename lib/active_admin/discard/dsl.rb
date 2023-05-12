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

        controller do
          def scoped_collection
            if params[:action] == 'index'
              if params[:discards]
                super.unscoped.discarded
              else
                super.kept
              end
            else
              super
            end
          end
        end

        action_item :discards, only: :index do
          if params[:discards]
            kept_count = collection_before_scope.with_discarded.kept.count
            javascript_tag('document.body.classList.add("discards");') + (
              link_to "Valides (#{kept_count})",
                      url_for(request.parameters.merge(discards: nil)),
                      class: 'discards-link green'
            )
          else
            discarded_count = collection_before_scope.with_discarded.discarded.count
            link_to "Corbeille (#{discarded_count})",
                    url_for(request.parameters.merge(discards: true)),
                    class: 'discards-link red'
          end
        end

        member_action :discard, method: :put do
          if resource.discard
            redirect_to request.referer,
                        notice: 'Mis à la corbeille'
          else
            flash[:error] = 'Impossible à mettre à la corbeille'
            redirect_to request.referer
          end
        end

        member_action :undiscard, method: :put do
          if resource.undiscard
            redirect_to request.referer,
                        notice: 'Sorti de la corbeille'
          else
            flash[:error] = 'Impossible à sortir de la corbeille'
            redirect_to request.referer
          end
        end

        member_action :really_destroy, method: :delete do
          if resource.destroy
            redirect_to polymorphic_path([:admin, collection.object.klass], scope: :discarded),
                        notice: 'Supprimé'
          else
            flash[:error] = 'Impossible à supprimer'
            redirect_to request.referer
          end
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
