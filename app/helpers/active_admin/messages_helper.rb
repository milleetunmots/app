module ActiveAdmin::MessagesHelper

  def child_support_call3_goals(id)
    ChildSupport.find(id).call3_goals || ''
  end

end
