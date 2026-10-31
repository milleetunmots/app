require 'zip'
require 'fast_excel'

class Child
  class ExportBooksV2Service
    attr_reader :errors
    attr_reader :zip_file

    SUMMARY_COLUMNS = ['Nom du module', 'Âges', 'Effectif', 'EAN', 'Livre', 'Cohorte', 'Module'].freeze

    # freeze_books : seul le job logistique du lundi fige les livres, les exports manuels de l'admin ne figent rien
    def initialize(group_ids: nil, freeze_books: false)
      @errors = []
      @group_ids = group_ids
      @freeze_books = freeze_books
    end

    def call
      # sans cohorte, chosen_modules_for_group renvoie toutes les cohortes : on ne les fige pas toutes
      if @freeze_books && @group_ids.blank?
        @errors << 'Aucune cohorte à exporter'
        return self
      end

      children_lists = find_children_lists

      excel_files = children_lists.map do |filename, children|
        service = Child::ExportBookExcelService.new(children: children).call

        { filename: "#{filename}.xlsx", file: service.workbook }
      end

      @errors << 'Aucun choix de module à programmer n\'a été trouvé' if excel_files.empty?

      if @errors.empty?
        excel_files << { filename: 'choix-modules.xlsx', file: generate_modules_summary }
        create_zip_file(excel_files)
        @freeze_books ? generate_logistic_export_and_freeze_books : generate_logistic_export
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
          module_label = "M#{module_num}"
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
      # livre enregistré s'il existe (garde-fou : le livre d'un module n'est pas censé changer pendant la semaine).
      # csm[:book_id] : book_id est délégué au livre
      chosen_modules.group_by { |csm| csm[:book_id] || csm.support_module_book_id }.each do |book_id, children_support_modules|
        book = Book.find(book_id) if book_id

        children = Child.where(id: children_support_modules.select(&:shippable?).map(&:child_id).uniq)

        filename = book.present? ? "#{book.ean} #{book.title} #{Time.zone.now.strftime("%d-%m-%Y")}" : 'Sans livre'
        children_list_sorted_by_module[filename] = children
      end

      children_list_sorted_by_module
    end

    # Avec le figement, les modules non expédiables sont lus aussi pour être figés « Non envoyé » :
    # fichiers et figement partent de la même liste, une adresse marquée entre les deux ne crée pas d'écart
    def chosen_modules
      @chosen_modules ||= ChildrenSupportModule.chosen_modules_for_group(@group_ids, include_unshippable: @freeze_books)
                                               .uniq { |csm| [csm.child_id, csm.parent_id] }
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

    def generate_logistic_export
      export = LogisticExport.new(group_modules: logistic_export_group_modules)
      export.archive.attach(
        io: File.open(@zip_file.path),
        filename: logistic_export_filename,
        content_type: 'application/zip'
      )
      export.save!
    rescue => e
      Rollbar.error(message: 'LogisticExport generation in ExportBooksV2Service', group_ids: @group_ids, error: e)
    end

    # ActiveStorage n'envoie un fichier qu'après le commit : l'archive est envoyée avant la transaction,
    # pour qu'un échec n'importe où laisse ni LogisticExport ni livre figé
    def generate_logistic_export_and_freeze_books
      blob = File.open(@zip_file.path) do |file|
        ActiveStorage::Blob.create_and_upload!(io: file, filename: logistic_export_filename, content_type: 'application/zip')
      end

      ActiveRecord::Base.transaction do
        export = LogisticExport.new(group_modules: logistic_export_group_modules)
        export.archive.attach(blob)
        export.save!
        freeze_books
      end
    rescue StandardError => e
      blob&.purge
      @errors << "Export logistique en échec : #{e.message}"
    end

    # modules 2 et suivants : le Module 1 n'est jamais retenu par le job logistique, l'attribution le fige
    def freeze_books
      group_ids = groups.select { |group| group.support_module_programmed >= 2 }.map(&:id)
      return if group_ids.empty?

      ChildrenSupportModule::SaveBookFromSupportModuleService.new(
        group_ids: group_ids,
        children_support_modules: chosen_modules.select { |csm| csm.child.group_id.in?(group_ids) }
      ).call
    end

    def groups
      @groups ||= Group.where(id: @group_ids).to_a
    end

    def logistic_export_group_modules
      groups.map { |group| { group_id: group.id, module_number: group.support_module_programmed } }
    end

    def logistic_export_filename
      group_label = groups.map { |g| g.name.parameterize }.join("-")
      "yls-export-#{group_label}-#{Time.zone.today.strftime('%d-%m-%Y')}.zip"
    end
  end
end
