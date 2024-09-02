module ActiveAdmin::MessagesHelper

  def child_support_call3_goals(id)
    ChildSupport.find_by(id: id)&.call3_goals
  end

end
