class BuzzExpert::GenerateFileService

  attr_reader :errors, :csv

  # objects: array of Hash {parent:, child:, ...}
  # variables: Hash {key => name} where @key can be found on objects
  # and @name is the header name
  def initialize(objects:, variables: {})
    @objects = objects
    @variables = variables
    @errors = []
  end

  def call
    csv_options = ActiveAdmin.application.csv_options.clone
    bom = csv_options.delete :byte_order_mark
    csv_options[:headers] = true

    @csv = bom + CSV.generate(csv_options) do |csv|

      # extract keys once to ensure unique order
      keys = @variables.keys

      # headers
      csv << [
        'Numéro du parent',
        "Prénom de l'enfant",
        "Nom de l'enfant"
      ] + keys.map do |key|
        @variables[key]
      end

      # rows
      @objects.each do |object|
        parent = object[:parent]
        child = object[:child]

        csv << [
          parent.phone_number,
          child.first_name,
          child.last_name
        ] + keys.map do |key|
          object[key]
        end
      end
    end

    self
  end

end
