class ChildSupportsController < ApplicationController

  def confirm_end_support
    find_child_support(params[:child_support_id], params[:parent1_sc])
    verify_child_support
    return if @child_support.tag_list.include?('arrêt appelante - programme')

    @child_support.tag_list.add('arrêt appelante - programme')
    @child_support.important_information = "#{@child_support.important_information}\nAccompagment arrêté le #{@child_support.stop_support_date.strftime('%d/%m/%Y')} pour le motif 'je ne souhaite pas être appelé' à la demande du parent"
    @child_support.save
    @child_support.children.each do |child|
      next if child.group_status == 'stopped'

		  child.group_status = 'stopped'
			child.group_end = Time.zone.today
			child.save
		end
  end

  def updated_at
    @child_support = ChildSupport.find_by(id: params[:child_support_id])
    not_found and return unless @child_support

    render json: {
      updated_at: @child_support.updated_at
    }
  end

  def call3_speaking_form
    handle_call3_form
  end

  def call3_observing_form
    handle_call3_form
  end

  private

  def find_child_support(child_support_id, security_code)
    @child_support = ChildSupport.find_by(id: child_support_id)

    not_found and return unless @child_support
    not_found and return unless @child_support.parent1.security_code == security_code
  end

  def verify_child_support
    not_found and return if @child_support.stop_support_caller_id.nil?
  end

  def handle_call3_form
    find_child_support(params[:cs], params[:sc])
    supporter_name = @child_support.supporter&.decorate&.first_name || '1001mots'
    current_child_name = @child_support.current_child&.first_name || 'Votre enfant'
    return if params[:supporter_name] == supporter_name && params[:current_child_name] == current_child_name

    redirect_to url_for(params.permit!.to_h.merge(supporter_name: supporter_name, current_child_name: current_child_name)) and return
  end
end
