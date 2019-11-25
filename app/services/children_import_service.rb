class ChildrenImportService

  attr_reader :errors

  def initialize(csv_file:, current_admin_user:)
    @csv_file = csv_file
    @current_admin_user = current_admin_user
    @errors = []
  end

  def call
    Child.transaction do
      CSV.foreach(@csv_file.path, headers: true, col_sep: ';').with_index do |row, i|
        line = i + 2
        # puts "line #{line}"
        # puts row.inspect

        # base
        attributes = {
          registration_source: row['registration_source']&.strip,
          registration_source_details: row['registration_source_details']&.strip,
          first_name: row['first_name']&.strip,
          last_name: row['last_name']&.strip,
          birthdate: Date.parse(row['birthdate']&.strip)
        }

        # parent 1
        parent1_phone_number = format_phone_number(row['parent1_phone_number']&.strip)
        parent1_first_name = row['parent1_first_name']&.strip
        parent1_last_name = row['parent1_last_name']&.strip
        existing_parent1 = Parent.where(phone_number: parent1_phone_number).order(:id).first
        if existing_parent1
          attributes[:parent1_id] = existing_parent1.id
          attributes[:parent2_id] = existing_parent1.children.order(:id).last.parent2_id
        else
          attributes[:parent1_attributes] = {
            gender: row['parent1_gender']&.strip == 'Maman' ? 'f' : 'm',
            first_name: parent1_first_name,
            last_name: parent1_last_name,
            phone_number: parent1_phone_number,
            address: row['parent1_address']&.strip,
            city_name: row['parent1_city_name']&.strip,
            postal_code: row['parent1_postal_code']&.strip
          }

          # parent 2
          parent2_gender = row['parent2_gender'] && (row['parent2_gender']&.strip == 'Maman' ? 'f' : 'm')
          if parent2_gender
            attributes[:parent2_attributes] = {
              gender: parent2_gender,
              first_name: row['parent2_first_name']&.strip,
              last_name: row['parent2_last_name']&.strip,
              phone_number: format_phone_number(row['parent2_phone_number']&.strip) || parent1_phone_number,
              address: attributes[:parent1_attributes][:address],
              city_name: attributes[:parent1_attributes][:city_name],
              postal_code: attributes[:parent1_attributes][:postal_code]
            }
          end
        end

        # child support
        child_support_important_information = row['child_support_important_information']&.strip
        if child_support_important_information
          attributes[:child_support_attributes] = {
            supporter_id: @current_admin_user.id,
            important_information: child_support_important_information
          }
        end

        # puts "attributes:", attributes.inspect
        child = Child.new(attributes)
        unless child.save
          @errors << [line, child.errors.full_messages]
          puts "error: #{child.errors.inspect}"
          raise ActiveRecord::Rollback
        end
      end
    end
    self
  end

  def format_phone_number(phone_number)
    return nil if phone_number.blank?
    phone = Phonelib.parse(
      [
        phone_number[0] == '0' ? '' : '0',
        phone_number
      ].join
    )
    phone.e164
  end

end
