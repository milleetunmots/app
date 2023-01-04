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

      excel_files = children_lists.map do |period, groups|
        groups.map do |group_name, children|
          service = Child::ExportBookExcelService.new(children: children).call

          { filename: "#{period}-#{group_name}.xlsx", file: service.workbook }
        end
      end.flatten

      @errors << 'Aucune cohorte active avec des enfants n\'a été trouvé' if excel_files.empty?

      create_zip_file(excel_files) if @errors.empty?
      self
    end

    # private

    def find_children_lists
      children_list_sorted_by_age_and_group = {}
      [:months_between_0_and_12, :months_between_12_and_24, :months_more_than_24].each do |age_period|
        children_list_sorted_by_group = {}
        Group.not_ended.each do |group|
          children_list = group.children.where(group_status: "active").send(age_period)
          children_list_sorted_by_group[group.name.to_sym] = children_list unless children_list.empty?
        end
        children_list_sorted_by_age_and_group[age_period] = children_list_sorted_by_group unless children_list_sorted_by_group.empty?
      end
      children_list_sorted_by_age_and_group
    end

    def create_zip_file(excel_files)
      @zip_file = Tempfile.new("test.zip")

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

      temp_files = nil
    end
  end
end
