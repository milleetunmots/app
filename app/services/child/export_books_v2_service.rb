require 'zip'
require 'fast_excel'

class Child
  class ExportBooksV2Service
    attr_reader :errors
    attr_reader :zip_file

    SUMMARY_COLUMNS = ['Nom du module', 'Âges', 'Effectif', 'EAN', 'Livre', 'Cohorte', 'Module'].freeze

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

      if @errors.empty?
        excel_files << { filename: 'choix-modules.xlsx', file: generate_modules_summary }
        create_zip_file(excel_files)
      end

      self
    end

    private

    def generate_modules_summary
      workbook = FastExcel.open
      worksheet = workbook.add_worksheet
      header_format = workbook.add_format(bold: true, bg_color: :'#70AD47', font_color: :white)
      worksheet.append_row(SUMMARY_COLUMNS, header_format)

      Group.where(id: @group_ids).each do |group|
        child_and_parent1_ids = group.children.joins(:child_support)
                                     .where(child_support: { address_suspected_invalid_at: nil })
                                     .active_group.pluck(:id, :parent1_id)

        summary = {}

        child_and_parent1_ids.each do |child_id, parent1_id|
          csm = ChildrenSupportModule.with_support_module
                                     .where(is_programmed: false)
                                     .find_by(child_id: child_id, parent_id: parent1_id)
          next unless csm

          module_num = csm.module_index - 1
          module_label = "Module #{module_num}"
          module_name = csm.support_module.name
          age_ranges = csm.support_module.decorate.display_age_ranges.to_sym

          key = [module_label, module_name, age_ranges]
          summary[key] ||= { count: 0 }
          summary[key][:count] += 1
          summary[key][:book_ean] ||= csm.book_ean.presence || csm.support_module.book&.ean
          summary[key][:book_title] ||= csm.book_title.presence || csm.support_module.book&.title
        end

        summary.each do |(module_label, module_name, age_key), values|
          worksheet.append_row([module_name, age_key, values[:count], values[:book_ean], values[:book_title], group.name, module_label])
        end
      end

      worksheet.set_columns_width(0, 3, 25)

      workbook
    end

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
          temp.close

          zipfile.add("#{excel_file[:filename].gsub('.xlsx', '').parameterize}.xlsx", temp.path)
        end
      end

      # Store tempfiles in an array so they are not automatically removed by the garbage collector
      # before the end of the creation of the zipfile
      # see: https://stackoverflow.com/questions/31237809/ruby-auto-deleting-temp-file

      temp_files = nil
    end
  end
end
