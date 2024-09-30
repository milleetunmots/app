class BookDecorator < BaseDecorator

  def book_support_modules
    arbre do
      ul do
        model.support_modules.decorate.each do |support_module|
          li support_module.admin_link
        end
      end
    end
  end

  def cover_link_tag(**options)
    return nil unless model.media.file.attached?

    options.merge!(source: model.media.file)
    image_link_tag(**options)
  end
end
