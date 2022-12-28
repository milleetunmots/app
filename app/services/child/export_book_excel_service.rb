class Child
  class ExportBookExcelService
    attr_reader :workbook

    COLUMNS = [
      { name: 'Nom', method: :last_name },
      { name: 'Adresse', method: :address},
      { name: 'Code postal', method: :postal_code },
      { name: 'Ville', method: :city_name },
      { name: 'Prénom enfant', method: :first_name }
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

      @children.decorate.each_with_index do |child, index|
        format = index % 2 == 0 ? even_format : odd_format
        row = COLUMNS.map { |column| child.public_send(column[:method]) }

        is_probably_duplicate = @children.kinda_spelled_like(child.name).size > 1
        format = duplicate_format if is_probably_duplicate

        @worksheet.append_row(row, format)
      end
    end

    def set_column_width
      @worksheet.set_column_width(0, width = 25)
      @worksheet.set_columns_width(1, 4, width = 20)
    end
  end
end
