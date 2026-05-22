module ApplicationHelper

  def toastr_method_for_flash(flash_type)
    case flash_type
    when 'success', 'error'
      flash_type
    when 'alert'
      :warning
    else
      :info
    end
  end

  def pluralize_without_count(count, noun)
    count == 1 ? noun : noun.pluralize
  end

  def summer_support_waiting?
    return false if ENV['SUMMER_SUPPORT_WAITING_START'].blank? || ENV['SUMMER_SUPPORT_WAITING_END'].blank?

    Date.current.between?(
      Date.strptime(ENV['SUMMER_SUPPORT_WAITING_START'], '%d/%m/%Y'),
      Date.strptime(ENV['SUMMER_SUPPORT_WAITING_END'], '%d/%m/%Y')
    )
  end

end
