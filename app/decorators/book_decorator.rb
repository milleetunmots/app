class BookDecorator < BaseDecorator

  def book_support_modules
    model.support_modules.each do |support_module|
      "#{support_module.name} #{support_module.decorate.display_age_ranges}"
    end
  end

end
