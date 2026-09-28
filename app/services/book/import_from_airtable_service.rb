class Book::ImportFromAirtableService

  # Les liens Airtable sont signés et temporaires : un téléchargement peut
  # légitimement échouer sans que l'import entier doive s'arrêter. Sur une URL
  # S3 signée, un délai dépassé ou une URL malformée sont bien plus probables
  # qu'un refus de connexion.
  DOWNLOAD_ERRORS = [
    OpenURI::HTTPError, SocketError, URI::InvalidURIError,
    Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError,
    Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ENETUNREACH,
    # Conservé en filet : attach ne lève pas, mais d'autres chemins ActiveStorage si.
    ActiveRecord::RecordInvalid
  ].freeze

  attr_reader :errors

  def initialize
    @airtable_books = Airtables::Book.all.map do |book|
      {
        ean: book['EAN'],
        title: book['Titre du livre'],
        # Array() : tous les livres n'ont pas de couverture renseignée
        cover: Array(book['Photo de la couverture']).first,
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

  # Le nom de fichier vient d'Airtable : réduit à son basename, il ne peut pas
  # désigner un chemin hors de tmp/images. Le nom d'origine reste transmis tel
  # quel à ActiveStorage, l'affichage n'est pas affecté.
  def tmp_path(filename)
    Rails.root.join('tmp/images', File.basename(filename))
  end

  # Télécharge une pièce jointe Airtable dans tmp/images et renvoie son chemin.
  # L'appelant est responsable de la suppression du fichier.
  def download_to_tmp(attachment)
    FileUtils.mkdir_p(Rails.root.join('tmp/images'))

    file_path = tmp_path(attachment['filename'])
    URI.parse(attachment['url']).open do |remote|
      File.open(file_path, 'wb') do |file|
        file.write(remote.read)
      end
    end
    file_path
  end

  # Isolée au même titre que les photos intérieures : une couverture en échec
  # ne doit pas interrompre l'import des livres suivants.
  def update_cover
    return if @cover.blank?
    return if @book.media&.name == @cover['filename']

    @to_save = true
    cover = build_cover
    if cover.save
      @book.media = cover
    else
      @errors[:cover] << cover_error(cover.errors.full_messages.join(', '))
    end
  rescue *DOWNLOAD_ERRORS => e
    @errors[:cover] << cover_error(e.message)
  ensure
    FileUtils.rm_f(tmp_path(@cover['filename'])) if @cover.present?
  end

  def build_cover
    cover = Media::Image.new(name: @cover['filename'])
    cover.file.attach(
      io: File.open(download_to_tmp(@cover)),
      filename: @cover['filename'],
      content_type: @cover['type']
    )
    cover
  end

  def cover_error(message)
    "Couverture #{@cover['filename']} (EAN #{@ean}) : #{message}"
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

  # La clé ne compare que ce qu'Airtable a annoncé, jamais ce qui a été
  # téléchargé : le nom est assaini des deux côtés comme le fait ActiveStorage
  # au stockage, et la taille retenue est celle déclarée, mémorisée sur le blob.
  # Comparer la taille réelle retéléchargerait à chaque passage dès qu'Airtable
  # annonce un nombre d'octets différent de ce qu'il sert.
  def airtable_photo_key(photo)
    [ActiveStorage::Filename.new(photo['filename'].to_s).sanitized, photo['size']]
  end

  def attached_interior_photos_by_key
    @book.interior_photos.includes(:blob).group_by do |attachment|
      # Repli sur la taille réelle pour les photos importées avant cette clé.
      [attachment.blob.filename.to_s,
       attachment.blob.metadata['airtable_size'] || attachment.blob.byte_size]
    end
  end

  def attach_interior_photo(photo)
    attached = @book.interior_photos.attach(
      io: File.open(download_to_tmp(photo)),
      filename: photo['filename'],
      content_type: photo['type'],
      metadata: { airtable_size: photo['size'] }
    )
    # attach ne lève pas quand la validation échoue : il renvoie false. Sans ce
    # contrôle, une photo refusée disparaîtrait sans erreur ni alerte Rollbar.
    record_photo_error(photo, @book.errors.full_messages.join(', ')) unless attached
  rescue *DOWNLOAD_ERRORS => e
    record_photo_error(photo, e.message)
  ensure
    # Chemin recalculé plutôt que mémorisé : le fichier doit disparaître même
    # si le téléchargement s'est interrompu en cours d'écriture.
    FileUtils.rm_f(tmp_path(photo['filename']))
  end

  def record_photo_error(photo, message)
    @errors[:interior_photos] << "Photo #{photo['filename']} (EAN #{@ean}) : #{message}"
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
