class Group

  class ChildrenSupportModulesInformationsService
    require 'fast_excel'
    require 'zip'

    attr_reader :zip_file, :zip_filename

    COLUMNS = %w[Module Âges Effectif EAN Livre].freeze

    def initialize(group_id, index)
      @group = Group.find(group_id)
      @index = index
      @support_modules_count = {}
      @workbook = FastExcel.open
      group_without_module_zero = @group.started_at < DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
      @module_num = group_without_module_zero ? @index : @index.to_i - 1
      @zip_filename = "Cohorte #{@group.name} - Choix modules #{@module_num}.zip"
    end

    def call
      child_and_parent1_ids.each do |child_id, parent1_id|
        csm = ChildrenSupportModule.with_support_module.find_by(child_id: child_id, parent_id: parent1_id, module_index: @index)
        next unless csm

        @support_modules_count[csm.support_module.name] ||= {}
        @support_modules_count[csm.support_module.name][csm.support_module.decorate.display_age_ranges.to_sym] ||= {count: 0}
        @support_modules_count[csm.support_module.name][csm.support_module.decorate.display_age_ranges.to_sym][:count] += 1
        @support_modules_count[csm.support_module.name][csm.support_module.decorate.display_age_ranges.to_sym][:book_ean] ||= csm.support_module.book&.ean
        @support_modules_count[csm.support_module.name][csm.support_module.decorate.display_age_ranges.to_sym][:book_title] ||= csm.support_module.book&.title
      end

      init_excel_file
      fill_exel_file
      create_zip_file

      self
    end

    private

    def child_and_parent1_ids
      @group.children.active_group.pluck(:id, :parent1_id)
    end

    def init_excel_file
      @worksheet = @workbook.add_worksheet
      @worksheet.append_row(COLUMNS, @workbook.add_format(bold: true, bg_color: :'#70AD47', font_color: :white))
    end

    def fill_exel_file
      @support_modules_count.each do |support_module, ages_count|
        ages_count.each do |age_key, age_value|
          @worksheet.append_row([support_module, age_key, age_value[:count], age_value[:book_ean], age_value[:book_title]])
        end
      end
      @worksheet.set_columns_width(0, 1, width = 25)
      # @worksheet.set_columns_width(1, 2, width = 20)
    end

    def create_zip_file
      @zip_file = Tempfile.new('export-children-support-module-infos.zip')

      temp_files = []

      Zip::File.open(@zip_file.path, Zip::File::CREATE) do |zipfile|
        temp = Tempfile.new("choix-modules.xlsx", binmode: true)
        temp_files << temp
        temp.write(@workbook.read_string)
        temp.rewind

        zipfile.add "choix-modules-#{@index.to_i.positive? ? @module_num : 'pas-programmé'}.xlsx", temp.path
      end

      # Store tempfiles in an array so they are not automatically removed by the garbage collector
      # before the end of the creation of the zipfile
      # see: https://stackoverflow.com/questions/31237809/ruby-auto-deleting-temp-file

      temp_files = nil
    end
  end
end
