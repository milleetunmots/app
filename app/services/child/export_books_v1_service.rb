require 'zip'

class Child
  class ExportBooksV1Service
    attr_reader :errors
    attr_reader :zip_file

    def initialize
      @errors = []
    end

    def call
      children_lists = find_children_lists

      excel_files = children_lists.map do |children|
        service = Child::ExportBookExcelService.new(children: children).call

        service.workbook
      end

      @errors << 'Aucune cohorte active avec des enfants n\'a été trouvé' if excel_files.empty?


      puts '--------------------------------------'
      puts '--------------------------------------'
      puts @errors.inspect

      create_zip_file(excel_files) if @errors.empty?
      self
    end

    private

    def find_children_lists
      [:months_between_0_and_12, :months_between_12_and_24, :months_more_than_24].map do |age_period|
        Group.not_ended.map do |group|
          group.children.where(group_status: "active").send(age_period)
        end
      end.flatten.compact
    end

    def create_zip_file(excel_files)
      @zip_file = Tempfile.new("test.zip")

      Zip::OutputStream.open(@zip_file) do |zipfile|
        excel_files.each_with_index do |excel_file, index|
          zipfile.put_next_entry("#{index}.xlsx")
          zipfile.puts(excel_file.read_string)
        end
      end
    end
  end
end
