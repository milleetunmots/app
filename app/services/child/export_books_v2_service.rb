require 'zip'

class Child
  class ExportBooksV2Service
    attr_reader :errors
    attr_reader :zip_file

    def initialize
      @errors = []
    end

    def call
      children_lists = find_children_lists

      excel_files = children_lists.map do |period, modules|
        modules.map do |module_name, children|
          service = Child::ExportBookExcelService.new(children: children).call

          { filename: "#{module_name} - #{period}.xlsx", file: service.workbook }
        end
      end.flatten

      @errors << 'Aucun choix de module à programmer n\'a été trouvé' if excel_files.empty?

      create_zip_file(excel_files) if @errors.empty?
      self
    end

    # private

    def find_children_lists
      children_list_sorted_by_age_and_module = {}
      chosen_modules = ChildrenSupportModule.includes(:child).with_support_module #.not_programmed

      chosen_modules.group_by(&:support_module_id).each do |support_module_id, children_support_modules|
        support_module = SupportModule.find(support_module_id)
        children_ids = children_support_modules.map(&:child).select { |child| child.group_status == "active" }.map(&:id)
        children = Child.where(id: children_ids)

        [:months_between_6_and_12, :months_between_12_and_18, :months_between_18_and_24].each do |age_period|
          children_list = children.send(age_period)

          if children_list.any?
            period_name =
              case age_period
              when :months_between_6_and_12
                '6_12'
              when :months_between_12_and_18
                '12_18'
              when :months_between_18_and_24
                '18_24'
              end
            children_list_sorted_by_age_and_module[period_name] ||= {}
            children_list_sorted_by_age_and_module[period_name][support_module.name.to_sym] = children_list
          end
        end
      end

      children_list_sorted_by_age_and_module
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

      # Store tempfiles in an array so they are not automatically removed by the garbage collector
      # before the end of the creation of the zipfile
      # see: https://stackoverflow.com/questions/31237809/ruby-auto-deleting-temp-file

      temp_files = nil
    end
  end
end
