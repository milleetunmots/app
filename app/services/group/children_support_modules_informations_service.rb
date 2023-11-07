class Group

  class ChildrenSupportModulesInformationsService
    require 'fast_excel'
    require 'zip'

    attr_reader :zip_file

    COLUMNS = %w[Module Effectif].freeze

    def initialize(group_id, index)
      @group = Group.find(group_id)
      @index = index
      @support_modules_count = Hash.new(0)
      @workbook = FastExcel.open
    end

    def call
      if @index.to_i.zero?
        last_csm_programmed_date = ChildrenSupportModule.joins(child: :group).where(groups: { id: @group.id }).where(children_support_modules: { is_programmed: true }).order('children_support_modules.created_at DESC').first.created_at
        child_and_parent1_ids.each do |child_id, parent1_id|
          csm = ChildrenSupportModule.with_support_module.find_by('child_id = ? AND parent_id = ? AND children_support_modules.created_at >= ? AND is_programmed = ? AND module_index = ?', child_id, parent1_id, last_csm_programmed_date.to_date, false, nil)
          @support_modules_count[csm.support_module.name.to_sym] += 1 if csm
        end
      else
        child_and_parent1_ids.each do |child_id, parent1_id|
          csm = ChildrenSupportModule.with_support_module.find_by(child_id: child_id, parent_id: parent1_id, module_index: @index)
          @support_modules_count[csm.support_module.name.to_sym] += 1 if csm
        end
      end

      init_excel_file
      fill_exel_file
      create_zip_file

      self
    end

    private

    def child_and_parent1_ids
      @group.children.pluck(:id, :parent1_id)
    end

    def init_excel_file

      @worksheet = @workbook.add_worksheet
      @worksheet.append_row(COLUMNS, @workbook.add_format(bold: true, bg_color: :'#70AD47', font_color: :white))
    end

    def fill_exel_file
      @support_modules_count.each do |support_module, count|
        @worksheet.append_row([support_module, count])
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

        zipfile.add "choix-modules-#{@index.to_i.positive? ? @index.to_i - 1 : 'pas-programmé'}.xlsx", temp.path
      end

      # Store tempfiles in an array so they are not automatically removed by the garbage collector
      # before the end of the creation of the zipfile
      # see: https://stackoverflow.com/questions/31237809/ruby-auto-deleting-temp-file

      temp_files = nil
    end
  end
end
