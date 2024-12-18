require 'zip'

class Child
  class ExportBooksV2Service
    attr_reader :errors
    attr_reader :zip_file

    def initialize(group_ids: nil)
      @errors = []
      @group_ids = group_ids
    end

    def call
      children_lists = find_children_lists

      excel_files = children_lists.map do |filename, children|
        service = Child::ExportBookExcelService.new(children: children).call

        { filename: "#{filename}.xlsx", file: service.workbook }
      end

      @errors << 'Aucun choix de module à programmer n\'a été trouvé' if excel_files.empty?

      create_zip_file(excel_files) if @errors.empty?
      self
    end

    private

    def find_children_lists
      children_list_sorted_by_module = {}
      chosen_modules = ChildrenSupportModule.chosen_modules_for_group(@group_ids)
      chosen_modules = chosen_modules.uniq { |csm| [csm.child_id, csm.parent_id] }
      chosen_modules.group_by(&:support_module_book_id).each do |support_module_book_id, children_support_modules|
        book = Book.find(support_module_book_id) if support_module_book_id

        children = Child.where(group_status: 'active', id: children_support_modules.map(&:child_id).uniq)

        filename = book.present? ? "#{book.ean} #{book.title} #{Time.zone.now.strftime("%d-%m-%Y")}" : 'Sans livre'
        children_list_sorted_by_module[filename] = children
      end

      children_list_sorted_by_module
    end

    def create_zip_file(excel_files)
      @zip_file = Tempfile.new('test.zip')

      temp_files = []

      Zip::File.open(@zip_file.path, Zip::File::CREATE) do |zipfile|
        excel_files.each_with_index do |excel_file, index|
          temp = Tempfile.new("file-#{index}.xlsx", binmode: true)
          temp_files << temp
          temp.write(excel_file[:file].read_string)
          temp.rewind

          zipfile.add excel_file[:filename], temp.path
        end
      end

      # Store tempfiles in an array so they are not automatically removed by the garbage collector
      # before the end of the creation of the zipfile
      # see: https://stackoverflow.com/questions/31237809/ruby-auto-deleting-temp-file

      temp_files = nil
    end
  end
end
