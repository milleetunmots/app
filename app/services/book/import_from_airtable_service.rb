class Book::ImportFromAirtableService

  attr_reader :errors

  def initialize
    @airtable_books = Airtables::Book.all.map do |book|
      {
        ean: book['EAN'],
        title: book['Titre du livre'],
        cover: book['Photo de la couverture'].first,
        # Le champ n'est pas renseigné pour tous les livres : Array(nil) => []
        interior_photos: Array(book['Photos intérieures']),
        modules: book['Modules']
      }
    end
    @errors = { support_modules: [], cover: [], interior_photos: [] }
  end

  def call
    @airtable_books.each do |airtable_book|
      @to_save = false
      @ean = airtable_book[:ean]
      @title = airtable_book[:title]
      @cover = airtable_book[:cover]
      @interior_photos = airtable_book[:interior_photos]
      @support_module_ids = []
      @modules = airtable_book[:modules]
      retrieve_support_modules
      @book = Book.find_by(ean: @ean)
      import_new_book
      update_title
      update_support_modules
      update_cover
      @book.save! if @to_save
      # Après la sauvegarde : un livre tout juste créé doit être persisté
      # avant qu'on puisse lui attacher des fichiers.
      sync_interior_photos
    end
    clean_missing_books
    self
  end

  private

  def retrieve_support_modules
    by_airtable_id = SupportModule.where(airtable_id: @modules).index_by(&:airtable_id)
    @modules.each do |record_id|
      support_module = by_airtable_id[record_id]
      if support_module
        @support_module_ids << support_module.id
      else
        @errors[:support_modules] << "Module Airtable introuvable : #{Airtables::Module.record_url(record_id)}"
      end
    end
  end

  def import_new_book
    return if @book.present?

    @book = Book.create(ean: @ean, title: @title)
  end

  def update_title
    return if @book.title == @title

    @to_save = true
    @book.title = @title
  end

  # Télécharge une pièce jointe Airtable dans tmp/images et renvoie son chemin.
  # L'appelant est responsable de la suppression du fichier.
  def download_to_tmp(attachment)
    save_dir = Rails.root.join('tmp', 'images')
    FileUtils.mkdir_p(save_dir)

    file_path = File.join(save_dir, attachment['filename'])
    URI.parse(attachment['url']).open do |remote|
      File.open(file_path, 'wb') do |file|
        file.write(remote.read)
      end
    end
    file_path
  end

  def update_cover
    return if @book.media&.name == @cover['filename']

    @to_save = true
    file_path = download_to_tmp(@cover)
    cover = Media::Image.new(name: @cover['filename'])
    cover.file.attach(
      io: File.open(file_path),
      filename: @cover['filename'],
      content_type: @cover['type']
    )
    @errors[:cover] << "Erreur lors de la sauvegarde de l'image #{@book.media&.name}" unless cover.save

    @book.media = cover
    FileUtils.rm_f(file_path)
  end

  # Airtable fait foi : les photos retirées là-bas sont supprimées ici, les
  # nouvelles sont téléchargées, et celles déjà présentes sont laissées telles
  # quelles — sans quoi le job nocturne retéléchargerait tout chaque nuit.
  # L'identité d'une photo tient au couple nom de fichier + taille : le nom seul
  # ne détecterait pas le remplacement d'une photo par une autre de même nom.
  def sync_interior_photos
    return unless @book&.persisted?

    desired = @interior_photos.index_by { |photo| airtable_photo_key(photo) }
    existing = attached_interior_photos_by_key

    existing.each { |key, attachments| purge_surplus(attachments, keep: desired.key?(key)) }
    (desired.keys - existing.keys).each { |key| attach_interior_photo(desired[key]) }
  end

  # Airtable ne référence qu'un exemplaire par clé. On purge donc ceux qui n'y
  # sont plus, et les surnuméraires qu'un import interrompu aurait laissés :
  # la clé ne les distinguant pas, ils resteraient sinon en base pour toujours.
  def purge_surplus(attachments, keep:)
    surplus = keep ? attachments.drop(1) : attachments
    surplus.each(&:purge)
  end

  def airtable_photo_key(photo)
    [photo['filename'], photo['size']]
  end

  def attached_interior_photos_by_key
    @book.interior_photos.includes(:blob)
         .group_by { |attachment| [attachment.blob.filename.to_s, attachment.blob.byte_size] }
  end

  def attach_interior_photo(photo)
    file_path = download_to_tmp(photo)
    @book.interior_photos.attach(
      io: File.open(file_path),
      filename: photo['filename'],
      content_type: photo['type']
    )
  ensure
    FileUtils.rm_f(file_path) if file_path
  end

  def update_support_modules
    return if @book.support_module_ids.sort == @support_module_ids.sort

    @to_save = true
    @book.support_module_ids = @support_module_ids
  end

  def clean_missing_books
    Book.where.not(ean: @airtable_books.pluck(:ean)).update(support_module_ids: [])
  end
end
