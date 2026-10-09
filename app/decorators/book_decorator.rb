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
    return nil unless model.media&.file&.attached?

    options.merge!(source: model.media.file)
    image_link_tag(**options)
  end

  # Couverture cliquable qui ouvre les pages du livre (couverture + photos intérieures)
  # dans un nouvel onglet, plutôt que l'image de couverture seule.
  def cover_content_link_tag(**options)
    return nil unless model.media&.file&.attached?

    cover = h.image_tag_with_max_size(**options, source: model.media.file)
    h.link_to cover, h.read_content_admin_book_path(model), target: '_blank', rel: 'noopener'
  end

  # Pages affichées dans la galerie du livre : couverture d'abord, puis photos intérieures.
  # Sans tri explicite, l'ordre des pièces jointes n'est pas garanti : on suit l'ordre d'import.
  def pages
    cover = model.media&.file&.attached? ? [{ label: 'Couverture', source: model.media.file }] : []
    photos = model.interior_photos_attachments.includes(:blob).order(:id).map.with_index(1) do |photo, number|
      { label: "Image #{number}", source: photo }
    end
    cover + photos
  end

  def interior_photos_tags(**options)
    return nil unless model.interior_photos.attached?

    h.safe_join(
      model.interior_photos.map { |photo| image_link_tag(**options, source: photo) },
      ' '
    )
  end
end
