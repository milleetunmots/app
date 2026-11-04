require 'active_admin/better_csv/dsl'
require 'active_admin/discard/dsl'
require 'active_admin/flash_task_links'
require 'active_admin/media/dsl'
require 'active_admin/paper_trail/dsl'
require 'active_admin/tags/dsl'
require 'active_admin/tasks/dsl'

::ActiveAdmin::DSL.send :include, ActiveAdmin::BetterCSV::DSL
::ActiveAdmin::DSL.send :include, ActiveAdmin::Discard::DSL
::ActiveAdmin::DSL.send :include, ActiveAdmin::Media::DSL
::ActiveAdmin::DSL.send :include, ActiveAdmin::PaperTrail::DSL
::ActiveAdmin::DSL.send :include, ActiveAdmin::Tags::DSL
::ActiveAdmin::DSL.send :include, ActiveAdmin::Tasks::DSL

# Allows rendering a partial above the scopes on the index page (even when the collection is empty).
# Usage: set @before_index_partial in a controller before_action.
# Example: @before_index_partial = { partial: 'path/to/partial', locals: { key: value } }
module ActiveAdminBeforeIndexPartial
  def main_content
    if (partial_info = assigns[:before_index_partial])
      text_node helpers.render(partial: partial_info[:partial], locals: partial_info.fetch(:locals, {}))
    end
    super
  end
end

ActiveAdmin::Views::Pages::Index.prepend(ActiveAdminBeforeIndexPartial)
ActiveAdmin::Views::Pages::Base.prepend(ActiveAdmin::FlashTaskLinks)

# Simulation de connexion (« Se connecter en tant que ») : bandeau permanent et classe
# `impersonating` sur le body, qui fait passer les formulaires en lecture seule (impersonation.js).
module ActiveAdminImpersonationBanner
  private

  def body_classes
    classes = super
    classes << 'impersonating' if Current.impersonating?
    classes
  end

  # Seul point d'extension d'ActiveAdmin en tête de #wrapper, avant le header
  def build_unsupported_browser
    super
    text_node helpers.render(partial: 'admin/impersonations/banner') if Current.impersonating?
  end
end

ActiveAdmin::Views::Pages::Base.prepend(ActiveAdminImpersonationBanner)
