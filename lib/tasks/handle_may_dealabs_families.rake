require 'roo'

namespace :oneshot do
  desc 'assign correct status & tags to may / dealabs families'
  task handle_may_dealabs_families: :environment do
    excel_file_path = ENV['MAY_DEALABS_FAMILIES_EXCEL_FILE_PATH']
    xlsx = Roo::Spreadsheet.open(excel_file_path)
    sheet_name = xlsx.sheets.first
    sheet = xlsx.sheet(sheet_name)
    lines = sheet.each(
			child_support_id: '#',
			status: 'Statut pour Mai 242',
			tag_status: 'Tag statut',
			tag_diploma: 'Tag diplôme',
			tag_bao: 'Tag BAO',
			tag_dealabs: 'Tag Dealabs'
		).drop(1) # drop headers line

		lines.each.with_index(2) do |line, index|
			next if line[:child_support_id].blank?

			child_support = ChildSupport.find_by(id: line[:child_support_id])
			case line[:status]
			when 'Mai 24'
				child_support.children.update(group_id: 76, group_status: 'active')
			when 'En attente'
				child_support.children.each do |c|
					next if  c.group_id.eql?(79)

					c.update(group_id: 77, group_status: 'active') if c.group_id.eql?(76)
				end
			when 'Non accompagné'
				child_support.children.update(group_status: 'not_supported')
			end

			child_support.tag_list.add(line[:tag_status]) unless line[:tag_status].blank?
			child_support.tag_list.add(line[:tag_diploma]) unless line[:tag_diploma].blank?
			child_support.tag_list.add(line[:tag_bao]) unless line[:tag_bao].blank?
			child_support.tag_list.add(line[:tag_dealabs]) unless line[:tag_dealabs].blank?
			child_support.save!
		end
  end
end
