class Book::ImportFromAirtableService

  def initialize
    @airtable_books = Airtables::Book.all.map { |book| { ean: book['EAN'], title: book['Titre du livre'], cover: book['Photo de la couverture'], modules: book['Modules'] } }
  end

  def call
    @airtable_books.each do |airtable_book|
      @to_save = false
      @ean = airtable_book[:ean]
      @title = airtable_book[:title]
      @support_module_ids = airtable_book[:modules].map do |module_id|
        airtable_module = Airtables::Module.find(module_id)
        SupportModule.where(name: airtable_module['titre'].strip, age_ranges: [airtable_module.ages]).first.id
      end
      @book = Book.find_by(ean: @ean)
      import_new_book
      update_title
      update_support_modules
      @book.save! if @to_save
    end
    self
  end

  private

  def import_new_book
    return if @book.present?

    @book = Book.create(ean: @ean, title: @title)
  end

  def update_title
    return if @book.title == @title

    @to_save = true
    @book.title = @title
  end

  def update_support_modules
    return if @book.support_module_ids.sort == @support_module_ids.sort

    @to_save = true
    @book.support_module_ids = @support_module_ids
  end
end
