class ChildSupportsController < ApplicationController

  def confirm_end_support
    find_child_support
    return if @child_support.tag_list.include?('arrêt appelante - programme')

    @child_support.tag_list.add('arrêt appelante - programme')
    @child_support.important_information = "#{@child_support.important_information}\nFamille arretée le #{@child_support.stop_support_date.strftime("%d/%m/%Y")} pour le motif 'renonciation' par le parent"
    @child_support.save
    @child_support.children.each do |child|
      next if child.group_status == 'stopped'

			child.group_status = 'stopped'
			child.group_end = Time.zone.today
			child.save
		end
  end

  private

  def find_child_support
    @child_support = ChildSupport.find_by(id: params[:child_support_id])

    not_found and return unless @child_support
    not_found and return unless @child_support.parent1.security_code == params[:parent1_sc]
    not_found and return if @child_support.stop_support_caller_id.nil?
  end
end
