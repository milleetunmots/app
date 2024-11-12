require 'csv'

class ChildSupport::CheckParentAddressService

  MESSAGE = "1001mots : vous n'avez pas reçu votre dernier livre ? Vérifiez votre adresse sur ce lien : {LINK}".freeze

  attr_reader :errors

  def initialize
    @lines = CSV.read(ENV['NOT_DELIVERED_BOOKS_CSV_PATH'])
  end

  def call
    @lines.each do |line|
      @address = line[4]
      @postal_code = line[6]
      @city_name = line[7]
      @parent = Parent.where('TRIM(LOWER(unaccent(address))) ILIKE TRIM(LOWER(unaccent(?))) AND TRIM(LOWER(unaccent(postal_code))) ILIKE TRIM(LOWER(unaccent(?))) AND TRIM(LOWER(unaccent(city_name))) ILIKE TRIM(LOWER(unaccent(?)))', "%#{@address}%", "%#{@postal_code}%", "%#{@city_name}%").first
      next unless @parent

      @child_support = @parent.current_child.child_support
      next if @child_support.is_address_suspected_invalid == true

      @child_support.update(is_address_suspected_invalid: true)
      send_verifiication_message
    end
    self
  end

  private

  def send_verifiication_message
    message =
  end

end
