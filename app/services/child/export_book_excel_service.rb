class Child
  class ExportBookExcelService
    attr_reader :workbook

    COLUMNS = [
      { name: 'N', method: nil },
      { name: 'Titre', method: :book_to_distribute_title },
      { name: 'Nom', method: :letterbox_name },
      { name: 'Adresse', method: :address },
      { name: 'Complement', method: :address_supplement },
      { name: 'Code postal', method: :postal_code },
      { name: 'Ville', method: :city_name },
      { name: 'Prénom enfant', method: :first_name },
      { name: 'Module', method: :support_module_not_programmed_name },
      { name: 'Age', method: :support_module_not_programmed_ages }
    ].freeze

    def initialize(children:)
      @children = children
    end

    def call
      create_excel_file
      add_headers
      add_children
      set_column_width

      self
    end

    private

    def create_excel_file
      @workbook = FastExcel.open
      @worksheet = @workbook.add_worksheet
    end

    def add_headers
      format = workbook.add_format(bold: true, bg_color: :'#70AD47', font_color: :white)
      row = COLUMNS.map { |column| column[:name] }

      @worksheet.append_row(row, format)
    end

    def add_children
      even_format = workbook.add_format(bg_color: :'#e2eFDA')
      odd_format = workbook.add_format(bg_color: :white)
      duplicate_format = workbook.add_format(bg_color: :orange)
      long_name_format = workbook.add_format(bg_color: :'#e71f55')

      @children.decorate.each_with_index do |child, index|
        format = index.even? ? even_format : odd_format
        row = COLUMNS.map do |column|
          column[:method].present? ? child.public_send(column[:method]) : (index + 1).to_s
        end

        is_probably_duplicate = @children.kinda_spelled_like(child.name).size > 1
        format = duplicate_format if is_probably_duplicate

        format = long_name_format if child.first_name.length >= 11

        @worksheet.append_row(row, format)
      end
    end

    def set_column_width
      @worksheet.set_column_width(0, width = 2)
      @worksheet.set_column_width(1, width = 28)
      @worksheet.set_columns_width(2, 3, width = 16)
      @worksheet.set_column_width(4, width = 20)
      @worksheet.set_columns_width(5, 6, width = 16)
      @worksheet.set_column_width(7, width = 25)
      @worksheet.set_column_width(8, width = 10)
    end
  end
end
