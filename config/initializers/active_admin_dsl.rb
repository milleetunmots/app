require 'active_admin/better_csv/dsl'
require 'active_admin/discard/dsl'
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
