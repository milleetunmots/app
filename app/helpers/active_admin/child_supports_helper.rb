module ActiveAdmin::ChildSupportsHelper

  def child_support_call1_parent_progress_select_collection
    ChildSupport::PARENT_PROGRESS.map do |v|
      [
        ChildSupport.human_attribute_name("call1_parent_progress.#{v}"),
        v
      ]
    end
  end

  def child_support_call1_reading_frequency_select_collection
    ChildSupport::READING_FREQUENCY.reverse.map do |v|
      [
        ChildSupport.human_attribute_name("call1_reading_frequency.#{v}"),
        v
      ]
    end
  end

  def child_support_call2_language_awareness_select_collection
    ChildSupport::LANGUAGE_AWARENESS.map do |v|
      [
        ChildSupport.human_attribute_name("call2_language_awareness.#{v}"),
        v
      ]
    end
  end

  def child_support_call2_parent_progress_select_collection
    child_support_call1_parent_progress_select_collection
  end

  def child_support_call2_program_investment_select_collection
    ChildSupport::PROGRAM_INVESTMENT.map do |v|
      [
        ChildSupport.human_attribute_name("call2_program_investment.#{v}"),
        v
      ]
    end
  end

  def child_support_call3_language_awareness_select_collection
    child_support_call2_language_awareness_select_collection
  end

  def child_support_call3_parent_progress_select_collection
    child_support_call1_parent_progress_select_collection
  end

  def child_support_call3_program_investment_select_collection
    child_support_call2_program_investment_select_collection
  end

end
