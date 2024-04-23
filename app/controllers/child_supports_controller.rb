class ChildSupportsController < ApplicationController

  def confirm_end_support
    find_child_support
    @child_support.support_stop_date = DateTime.now
    @child_support.important_information = "#{@child_support.important_information}\nFamille arretée le #{@child_support.support_stop_date.strftime("%d/%m/%Y")} par le parent"
    @child_support.tag_list.add('arrêt appelante - programme')
    @child_support.save
    @child_support.children.each do |child|
			child.group_status = 'stopped'
			child.group_end = Time.zone.today
			child.save
		end
  end

  private

  def find_child_support
    @child_support = ChildSupport.find(params[:child_support_id])

    not_fount and return unless @child_support
    not_found and return unless @child_support.parent1.security_code == params[:parent1_sc]
  end
end
