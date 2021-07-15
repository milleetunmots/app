module ActiveAdmin::ChildSupportsHelper

  def child_support_supporter_select_collection
    AdminUser.order(:name).map(&:decorate)
  end

  ### shared

  def child_support_call_language_awareness_select_collection
    ChildSupport::LANGUAGE_AWARENESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_language_awareness.#{v}"),
        v
      ]
    end
  end

  def child_support_call_parent_progress_select_collection
    ChildSupport::PARENT_PROGRESS.map do |v|
      [
        ChildSupport.human_attribute_name("call_parent_progress.#{v}"),
        v
      ]
    end
  end

  def child_support_call_reading_frequency_select_collection
    ChildSupport::READING_FREQUENCY.reverse.map do |v|
      [
        ChildSupport.human_attribute_name("call_reading_frequency.#{v}"),
        v
      ]
    end
  end

  def child_support_call_sendings_benefits_select_collection
    ChildSupport::SENDINGS_BENEFITS.map do |v|
      [
        ChildSupport.human_attribute_name("call_sendings_benefits.#{v}"),
        v
      ]
    end
  end

  def child_support_books_quantity
    ChildSupport::BOOKS_QUANTITY.map do |v|
      [
        ChildSupport.human_attribute_name("books_quantity.#{v}"),
        v
      ]
    end
  end

end
