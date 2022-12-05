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

      puts '##############################'
      puts '##############################'
      puts '##############################'
      puts children_lists.inspect

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
          group.children.where(group_status: "active").send(:age_period)
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


# # frozen_string_literal: true

# require 'zip'

# class SynthesisExport
#   class GenerateZipFileService
#     def initialize(synthesis_export, syntheses:)
#       @synthesis_export = synthesis_export
#       @syntheses = syntheses
#     end

#     def call
#       return if @synthesis_export.reload.canceled?

#       create_zip_file
#       @synthesis_export.zip_file.attach(
#         io: @zip,
#         filename: @synthesis_export.zip_filename,
#         content_type: 'application/zip'
#       ) unless @synthesis_export.reload.canceled?
#       delete_temp_file
#     end

#     private

#     def create_zip_file
#       last_request_made_at = Time.current

#       @zip = Tempfile.new(@synthesis_export.zip_filename)

#       Zip::OutputStream.open(@zip) do |zipfile|
#         @syntheses.each do |synthesis|
#           if Time.current > last_request_made_at + 1.minute
#             break if @synthesis_export.reload.canceled?

#             last_request_made_at = Time.current
#           end

#           zipfile.put_next_entry(synthesis_filename(synthesis))
#           zipfile.puts(transformed_file(synthesis))

#           @synthesis_export.increment!(:treated_syntheses_count)
#         end
#       end
#     end

#     def delete_temp_file
#       @zip.close
#       @zip.unlink
#     end

#     def synthesis_filename(synthesis)
#       "#{synthesis.take.line_key}.#{@synthesis_export.format}"
#     end
