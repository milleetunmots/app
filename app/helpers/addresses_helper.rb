module AddressesHelper
  def google_places_api_tag
    javascript_include_tag "https://maps.googleapis.com/maps/api/js?libraries=places&key=#{ENV['GOOGLE_MAPS_API_KEY']}"
  end

  def address_input(form, options = {})
    prefix = options.delete(:prefix) || ""
    [
      address_address_input(form, prefix, options),
      address_postal_code_input(form, prefix),
      address_city_name_input(form, prefix)
    ].compact.join.html_safe
  end

  def address_address_input(form, prefix, options)
    form.input "#{prefix}address".to_sym,
      as: :string,
      input_html: {
        id: "address-#{prefix}address".to_sym,
        data: {
          maps_autocomplete: {
            target: {
              address: "#address-#{prefix}address",
              postal_code: "#address-#{prefix}postal_code",
              locality: "#address-#{prefix}city_name"
            }
          }.merge(options)
        }
      }
  end

  def address_postal_code_input(form, prefix)
    key = "#{prefix}postal_code".to_sym
    return unless form.object.has_attribute?(key)

    form.input key,
      input_html: {
        id: "address-#{key}"
      }
  end

  def address_city_name_input(form, prefix)
    key = "#{prefix}city_name".to_sym
    return unless form.object.has_attribute?(key)

    form.input key,
      input_html: {
        id: "address-#{key}"
      }
  end
end
