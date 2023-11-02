class Group

  class ChildrenSupportModulesInformationsService

    attr_reader :workbook

    COLUMNS = %w[Module Effectif].freeze

    def initialize(group_id, index)
      @group = Group.find(group_id)
      @index = index
      @support_modules_count = Hash.new(0)
      @workbook = FastExcel.open("test.xlsx")
      @errors = []
    end

    def call
      child_and_parent1_ids.each do |child_id, parent1_id|
        csm = ChildrenSupportModule.find_by(child_id: child_id, parent_id: parent1_id, module_index: @index)
        @support_modules_count[csm.support_module.name.to_sym] += 1 if csm
      end

      init_excel_file
      fill_exel_file

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
      @worksheet.set_column_width(0, width = 25)
      @worksheet.set_columns_width(1, 4, width = 20)
    end
  end
end
