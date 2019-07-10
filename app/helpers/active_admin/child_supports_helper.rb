module ActiveAdmin::ChildSupportsHelper

  def child_support_call1_parent_progress_select_collection
    Hash[
      ChildSupport::PARENT_PROGRESS.map do |v|
        [
          ChildSupport.human_attribute_name("call1_parent_progress.#{v}"),
          v
        ]
      end
    ]
  end

  def child_support_call2_program_investment_select_collection
    Hash[
      ChildSupport::PROGRAM_INVESTMENT.map do |v|
        [
          ChildSupport.human_attribute_name("call2_program_investment.#{v}"),
          v
        ]
      end
    ]
  end

  def child_support_call3_program_investment_select_collection
    child_support_call2_program_investment_select_collection
  end

end
