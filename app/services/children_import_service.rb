class ChildrenImportService

  attr_reader :errors

  def initialize(csv_file:)
    @csv_file = csv_file
    @errors = []
  end

  def call
    CSV.foreach(@csv_file.path, headers: true, col_sep: ';').with_index do |row, i|
      line = i + 1
      puts "line #{line}"
      puts row.inspect

      attributes = {
        registered_by: row["NOM Prénom du professionnel effectuant l'inscription"],
        first_name: row["Prénom de l'enfant"],
        last_name: row["NOM de l'enfant"],
        birthdate: Date.parse(row["Date de naissance de l'enfant"])
      }
      parent1_last_name, parent1_first_name = split_full_name(row["NOM Prénom parent n°1"])
      attributes[:parent1_attributes] = {
        gender: row["Il s'agit de"] == 'Maman' ? 'f' : 'm',
        first_name: parent1_first_name,
        last_name: parent1_last_name,
        email: row["Adresse e-mail"],
        phone_number: row["N° de portable parent n°1"],
        address: row["Adresse"],
        city_name: row["Ville"],
        postal_code: row["Code postal"]
      }
      parent2_gender = row["Il s'agit de "] && (row["Il s'agit de "] == 'Maman' ? 'f' : 'm')
      if parent2_gender
        parent2_last_name, parent2_first_name = split_full_name(row["NOM Prénom parent n°2"])
        attributes[:parent2_attributes] = {
          gender: parent2_gender,
          first_name: parent2_first_name,
          last_name: parent2_last_name,
          phone_number: row["N° de portable parent n°2"],
          address: attributes[:parent1_attributes][:address],
          city_name: attributes[:parent1_attributes][:city_name],
          postal_code: attributes[:parent1_attributes][:postal_code]
        }
      end
      puts "attributes:", attributes.inspect
      child = Child.new(attributes)
      unless child.save
        @errors << [line, child.errors.full_messages]
        break
      end
    end
    self
  end

  def split_full_name(full_name)
    splitted = full_name.split(' ')
    return splitted.shift, splitted.join(' ')
  end

end
