class Book::ImportFromAirtableService

  attr_reader :errors

  def initialize
    @airtable_books = Airtables::Book.all.map { |book| { ean: book['EAN'], title: book['Titre du livre'], cover: book['Photo de la couverture'].first, modules: book['Modules'] } }
    @errors = { support_modules: [], cover: [] }
  end

  def call
    Media::Image.skip_callback(:save, :after, :upload_file_to_spot_hit)
    @airtable_books.each do |airtable_book|
      # @to_save = false
      @ean = airtable_book[:ean]
      @title = airtable_book[:title]
      @cover = airtable_book[:cover]
      @support_module_ids = []
      @modules = airtable_book[:modules]
      # retrieve_support_modules
      @book = Book.find_by(ean: @ean)
      # import_new_book
      # update_title
      # update_support_modules
      update_cover
      # @book.save! if @to_save
      @book.save!
    end
    clean_missing_books
    Media::Image.set_callback(:save, :after, :upload_file_to_spot_hit)
    self
  end

  private

  def retrieve_support_modules
    @modules.map do |module_id|
      airtable_module = Airtables::Module.find(module_id)
      support_module = SupportModule.where(name: airtable_module['titre'].strip, age_ranges: [airtable_module.ages]).first
      if support_module.present?
        @support_module_ids << support_module.id
      else
        @errors[:support_modules] << "#{airtable_module['titre']} #{airtable_module.ages} introuvable"
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

  def download_cover
    save_dir = Rails.root.join('tmp', 'images')
    FileUtils.mkdir_p(save_dir) unless Dir.exist?(save_dir)

    file_path = File.join(save_dir, @cover['filename'])
    URI.open(@cover['url']) do |image|
      File.open(file_path, 'wb') do |file|
        file.write(image.read)
      end
    end
    file_path
  end

  def update_cover
    # return if @book.media&.name == @cover['filename']

    # @to_save = true
    cover = Media::Image.new(name: @cover['filename'])
    cover.file.attach(
      io: File.open(download_cover),
      filename: @cover['filename'],
      content_type: @cover['type']
    )
    @errors[:cover] << "Erreur lors de la sauvegarde de l'image #{@book.media&.name}" unless cover.save

    @book.media = cover
    FileUtils.rm_f(download_cover)
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
