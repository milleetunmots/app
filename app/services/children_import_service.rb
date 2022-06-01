class ChildrenImportService

  attr_reader :errors

  def initialize(csv_file:)
    @csv_file = csv_file
    @errors = []
  end

  def call
    Child.transaction do
      CSV.foreach(@csv_file.path, headers: true, col_sep: ',').with_index do |row, i|
        line = i + 2
        # puts "line #{line}"
        # puts row.inspect

        # base
        attributes = {
          registration_source: case row['registration_source']&.strip&.downcase
          when 'amis' then :friends
          when 'pmi' then :pmi
          when 'orthophoniste' then :therapist
          when 'creche' then :nursery
          when 'reinscription' then :resubscribing
          else :other
          end,
          registration_source_details: row['registration_source_details']&.strip || '?',
          first_name: row['first_name']&.strip,
          last_name: row['last_name']&.strip,
          birthdate: Date.parse(row['birthdate']&.strip),
          group_id: row['group_id']&.strip
        }

        # fecth a few parent attributes
        parent1_gender = row['parent1_gender']&.strip == 'Maman' ? 'f' : 'm'
        parent1_phone_number = format_phone_number(row['parent1_phone_number']&.strip)
        parent1_first_name = row['parent1_first_name']&.strip
        parent1_last_name = row['parent1_last_name']&.strip
        parent2_gender = row['parent2_gender'] && (row['parent2_gender']&.strip == 'Maman' ? 'f' : 'm')
        parent2_phone_number = format_phone_number(row['parent2_phone_number']&.strip)
        parent2_first_name = row['parent2_first_name']&.strip
        parent2_last_name = row['parent2_last_name']&.strip

        # link to existing parents ?
        existing_parent1 = Parent.where(phone_number: parent1_phone_number).order(:id).first
        if existing_parent1
          attributes[:parent1_id] = existing_parent1.id
          attributes[:parent2_id] = existing_parent1.children.order(:id).last.parent2_id
        else

          # new parent 1
          use_default_letterbox_name = row['parent1_letterbox_name']&.strip.blank?

          attributes[:parent1_attributes] = {
            gender: parent1_gender,
            first_name: parent1_first_name,
            last_name: parent1_last_name,
            phone_number: parent1_phone_number,
            letterbox_name: (
              use_default_letterbox_name ? [parent1_first_name, parent1_last_name].compact.join(' ') : row['parent1_letterbox_name']&.strip
            ),
            address: row['parent1_address']&.strip,
            city_name: row['parent1_city_name']&.strip,
            postal_code: row['parent1_postal_code']&.strip,
            terms_accepted_at: Time.now
          }

          # parent 2
          if parent2_gender
            if use_default_letterbox_name
              attributes[:parent1_attributes][:letterbox_name]  = [
                attributes[:parent1_attributes][:letterbox_name],
                '-',
                parent2_first_name,
                parent2_last_name
              ].compact.join(' ')
            end

            attributes[:parent2_attributes] = {
              gender: parent2_gender,
              first_name: parent2_first_name,
              last_name: parent2_last_name,
              phone_number: parent2_phone_number || parent1_phone_number,
              letterbox_name: attributes[:parent1_attributes][:letterbox_name],
              address: attributes[:parent1_attributes][:address],
              city_name: attributes[:parent1_attributes][:city_name],
              postal_code: attributes[:parent1_attributes][:postal_code],
              terms_accepted_at: Time.now
            }
          end
        end

        # child support
        child_support_important_information = row['child_support_important_information']&.strip
        if child_support_important_information
          attributes[:child_support_attributes] = {
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
